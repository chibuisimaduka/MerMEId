xquery version "1.0" encoding "UTF-8";

module namespace  app="http://kb.dk/this/listapp";

declare namespace file="http://exist-db.org/xquery/file";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace ht="http://exist-db.org/xquery/httpclient";
declare namespace m="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xl="http://www.w3.org/1999/xlink";

declare variable $app:notbefore := request:get-parameter("notbefore","") cast as xs:string;
declare variable $app:notafter  := request:get-parameter("notafter","") cast as xs:string;
declare variable $app:coll   := request:get-parameter("c",           "") cast as xs:string;
declare variable $app:query  := request:get-parameter("query",       "");
declare variable $app:page   := request:get-parameter("page",        "1") cast as xs:integer;
declare variable $app:number := request:get-parameter("itemsPerPage","20")   cast as xs:integer;
declare variable $app:genre  := request:get-parameter("genre",       "") cast as xs:string;

declare variable $app:from     := ($app:page - 1) * $app:number + 1;
declare variable $app:to       :=  $app:from      + $app:number - 1;

declare variable $app:published_only := 
request:get-parameter("published_only","") cast as xs:string;

declare function app:options() as node()*
{ 
let $options:= 
  (
  <option value="">All documents</option>,
  <option value="any">Published</option>,
  <option value="pending">Modified</option>,
  <option value="unpublished">Unpublished</option>)

  return $options
};


declare function app:pass-as-hidden() as node()* {
  let $inputs :=
    (
    <input name="published_only" type="hidden" value="{$app:published_only}"   />,
    <input name="c"              type="hidden" value="{$app:coll}"   />,
    <input name="query"          type="hidden" value="{$app:query}"  />,
    <input name="page"           type="hidden" value="{$app:page}"   />,
    <input name="itemsPerPage"   type="hidden" value="{$app:number}" />,
    <input name="genre"          type="hidden" value="{$app:genre}" />,
    <input name="notbefore"      type="hidden" value="{$app:notbefore}" />,
    <input name="notafter"      type="hidden" value="{$app:notafter}" />)
    return $inputs
};

declare function app:generate-href($field as xs:string,
  $value as xs:string) as xs:string {
    let $inputs := app:pass-as-hidden()
    let $pars   :=
    for $inp in $inputs

    let $str:=
      if($field = $inp/@name/string() ) then
	string-join(($field,fn:escape-uri($value,true())),"=")
      else
	string-join(($inp/@name,fn:escape-uri($inp/@value,true())),"=")
	return 
	  $str

	  let $link := string-join($pars,"&amp;")
	  return $link

  };


  declare function app:pass-as-hidden-except(
    $field as xs:string)  as node()* 
    {

      let $inputs:=
      for $input in app:pass-as-hidden()
      return
	if($input/@name ne $field) then
	  $input
	else
	  if($input/@name eq "page") then
	    (<input name="page" type="hidden" value="1" />)
	  else
	    ()
	    
	    return $inputs
    };

    declare function app:get-publication-reference($doc as node() )  as node()* 
    {
      let $doc-name:=util:document-name($doc)
      let $color_style := 
	if(doc-available(concat("public/",$doc-name))) then
	  (let $public_hash:=util:hash(doc(concat("public/",$doc-name)),'md5')
	  let $dcm_hash:=util:hash($doc,'md5')
	  return
	    if($dcm_hash=$public_hash) then
	      "publishedIsGreen"
	    else
	      "pendingIsYellow")
            else
	      "unpublishedIsRed"

	      let $form:=
	      <form id="formsourcediv{$doc-name}"
	      action="/storage/list_files.xq" 
	      method="post" style="display:inline;">
	      
		<div id="sourcediv{$doc-name}"
 		style="display:inline;">
		
		  <input id="source{$doc-name}" 
		  type="hidden" 
		  value="publish" 
		  name="dcm/{$doc-name}" 
		  title="file name"/>

		  <label class="{$color_style}" for='checkbox{$doc-name}'>
		    <input id='checkbox{$doc-name}'
		    onclick="add_publish('sourcediv{$doc-name}',
		    'source{$doc-name}',
		    'checkbox{$doc-name}');" 
		    type="checkbox" 
		    name="button" 
		    value="" 
		    title="publish"/></label>

		</div>
	      </form>
	      return $form
    };

    declare function app:get-edition-and-number($doc as node() ) as xs:string* {

      let $c := 
	$doc//m:fileDesc/m:seriesStmt/m:identifier[@type="file_collection"][1]/string()
	return ($c,$doc//m:meiHead/m:workDesc/m:work[1]/m:identifier[@type=$c]/string())

    };

    declare function app:view-document-reference($doc as node()) as node() {
      (: it is assumed that we live in /storage :)
      let $ref := 
      <a  target="_blank"
      title="View" 
      href="/storage/present.xq?doc={util:document-name($doc)}">
	{$doc//m:workDesc/m:work[1]/m:titleStmt/m:title[string()][1]/string()}
      </a>
      return $ref
    };

    declare function app:public-view-document-reference($doc as node()) as node() {
      (: it is assumed that we live in /storage :)
      let $ref := 
      <a  title="View" 
      href="/storage/document.xq?doc={util:document-name($doc)}">
	{$doc//m:workDesc/m:work[1]/m:titleStmt/m:title[string()][1]/string()}
      </a>
      return $ref
    };
    
    declare function app:edit-form-reference($doc as node()) as node() 
    {
      (: 
      Beware: Partly hard coded reference here!!!
      It still assumes that the document resides on the same host as this
      xq script but on port 80

      The old form is called edit_mei_form.xml the refactored one starts on
      edit-work-case.xml 
      :)

      let $form-id := util:document-name($doc)
      let $ref := 
      <form id="edit{$form-id}" 
      action="/orbeon/xforms-jsp/mei-form/" style="display:inline;" method="get">

	<input type="hidden"
        name="uri"
	value="http://{request:get-header('HOST')}/editor/forms/mei/edit-work-case.xml" />
	<input type="hidden"
 	name="doc"
	value="{util:document-name($doc)}" />
	<input type="image"
 	title="Edit" 
	src="/editor/images/edit.gif" 
	alt="Edit" />
	{app:pass-as-hidden()}
      </form>

      return $ref

    };

    declare function app:delete-document-reference($doc as node()) as node() 
    {
      let $form-id := util:document-name($doc)
      let $uri     := concat("/db/public/",util:document-name($doc))
      let $form := 
	if(doc-available($uri)) then
	<span>
	  <img src="/editor/images/remove_disabled.gif" alt="Remove (disabled)" title="Only unpublished files may be deleted"/>
	</span>
      else
      <form id="del{$form-id}" 
      action="http://{request:get-header('HOST')}/filter/delete/dcm/{util:document-name($doc)}"
      method="post" 
      style="display:inline;">
	{app:pass-as-hidden()}
	<input type="hidden" 
	name="file"
	value="{request:get-header('HOST')}/storage/dcm/{util:document-name($doc)}"
	title="file name"/>
	<input 
	onclick="{string-join(('show_confirm(&quot;del',$form-id,'&quot;,&quot;',$doc//m:workDesc/m:work/m:titleStmt/m:title[string()]/string()[1],'&quot;);return false;'),'')}" 
	type="image" 
	src="/editor/images/remove.gif"  
	name="button"
	value="delete"
	title="Delete"/>
      </form>
      return  $form
    };

    declare function app:list-title() 
    {
      let $title :=
	if(not($app:coll)) then
	  "All documents"
	else
	  ($app:coll, " documents")

	  return $title
    };

    declare function app:navigation( 
      $list as node()* ) as node()*
      {

	let $total := fn:count($list/m:meiHead)
	let $uri   := "" 
	let $nextpage := ($app:page+1) cast as xs:string

	let $next     :=
	  if($app:from + $app:number <$total) then
	    (element a {
	      attribute rel   {"next"},
	      attribute title {"Go to next page"},
	      attribute style {"text-decoration: none;"},
	      attribute href {
		fn:string-join((
		  $uri,"?",
		  app:generate-href("page",$nextpage)),"")
	      },
	      element img {
		attribute src {"/editor/images/next.png"},
		attribute alt {"Next"},
		attribute border {"0"}
	      }
	    })
	  else
	    ("") 

	    let $prevpage := ($app:page - 1) cast as xs:string

	    let $previous :=
	      if($app:from - $app:number + 1 > 0) then
		(
		  element a {
		    attribute rel {"prev"},
		    attribute title {"Go to previous page"},
		    attribute style {"text-decoration: none;"},
		    attribute href {
       		      fn:string-join(
			($uri,"?",
			app:generate-href("page",$prevpage)),"")},
			element img {
			  attribute src {"/editor/images/previous.png"},
			  attribute alt {"Previous"},
			  attribute border {"0"}
			}
		  })
		else
		  ("") 

		  let $app:page_nav := for $p in 1 to fn:ceiling( $total div $app:number ) cast as xs:integer
		  return 
		    (if(not($app:page = $p)) then
		    element a {
		      attribute title {"Go to page ",xs:string($p)},
		      attribute href {
       			fn:string-join(
			  ($uri,"?",
			  app:generate-href("page",xs:string($p))),"")
		      },
		      ($p)
		    }
		  else 
		    element span {
		      attribute style {"color:#999;"},
		      ($p)
		    }
		  )
		  let $links := ( 
		    element div {
		      element strong {
			"Found ",$total," files"
		      },
		      (<form action="" id="itemsPerPageForm" style="display:inline;">
		      <select name="itemsPerPage" onchange="this.form.submit();return true;"> 
			{(
			  element option {attribute value {"10"},
			  if($app:number=10) then 
			    attribute selected {"selected"}
			  else
			    "",
			    "10 per page"},
			    element option {attribute value {"20"},
			    if($app:number=20) then 
			      attribute selected {"selected"}
			    else
			      "",
			      "20 per page"},
			      element option {attribute value {"50"},
			      if($app:number=50) then 
				attribute selected {"selected"}
			      else
				"",
				"50 per page"},
				element option {attribute value {"100"},
				if($app:number=100) then 
				  attribute selected {"selected"}
				else
				  "",
				  "100 per page"},
				  element option {attribute value {$total cast as xs:string},
				  if($app:number=$total) then 
				    attribute selected {"selected"}
				  else
				    "",
				    "all"}
			 )}
		      </select>

		      {app:pass-as-hidden-except("itemsPerPage")}
		      
		      </form>),
		      element p {
			$previous,"&#160;",
			$app:page_nav,
			"&#160;", $next}
		    })
		    return $links
      };
