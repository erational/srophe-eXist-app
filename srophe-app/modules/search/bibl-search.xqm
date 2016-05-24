xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace bibls="http://syriaca.org/bibls";
import module namespace functx="http://www.functx.com";
import module namespace common="http://syriaca.org/common" at "common.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $bibls:q {request:get-parameter('q', '')};
declare variable $bibls:title {request:get-parameter('title', '')};
declare variable $bibls:author {request:get-parameter('author', '')};
declare variable $bibls:idno {request:get-parameter('idno', '')};
declare variable $bibls:subject {request:get-parameter('subject', '')};
declare variable $bibls:id-type {request:get-parameter('id-type', '')};
declare variable $bibls:pub-place {request:get-parameter('pub-place', '')};
declare variable $bibls:publisher {request:get-parameter('publisher', '')};
declare variable $bibls:date {request:get-parameter('date', '')};

(:~
 : Build full-text keyword search over all tei:place data
 : @param $q query string
:)
declare function bibls:keyword() as xs:string? {
    if($bibls:q != '') then concat("[ft:query(.,'",common:clean-string($bibls:q),"',common:options())]")
    else ()    
};

declare function bibls:title() as xs:string? {
    if($bibls:title != '') then concat("[ft:query(descendant::tei:title,'",common:clean-string($bibls:title),"',common:options())]")
    else ()    
};

declare function bibls:author() as xs:string? {
    if($bibls:author != '') then concat("[ft:query(descendant::tei:author,'",common:clean-string($bibls:author),"',common:options()) or ft:query(descendant::tei:editor,'",common:clean-string($bibls:author),"',common:options())]")
    else ()    
};

(:
 : NOTE: Forsee issues here if users want to seach multiple ids at one time. 
 : Thinking of how this should be enabled. 
:)
declare function bibls:idno() as xs:string? {
    if($bibls:idno != '') then 
        let $id := replace($bibls:idno,'[^\d\s]','')
        let $syr-id := concat('http://syriaca.org/bibl/',$id)
        return 
            if($bibls:id-type != '') then concat("[descendant::tei:idno[@type='",$bibls:id-type,"'][normalize-space(.) = '",$id,"']]")
            else concat("[descendant::tei:idno[normalize-space(.) = '",$id,"' or .= '",$syr-id,"']]")
    else ()    
};

declare function bibls:pub-place() as xs:string? {
    if($bibls:pub-place != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:pubPlace,'",common:clean-string($bibls:pub-place),"',common:options())]")
    else ()  
};

declare function bibls:publisher() as xs:string? {
    if($bibls:publisher != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:publisher,'",common:clean-string($bibls:publisher),"',common:options())]")
    else ()  
};

declare function bibls:date() as xs:string? {
    if($bibls:date != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:date,'",common:clean-string($bibls:date),"',common:options())]")
    else ()  
};

declare function bibls:subject() as xs:string?{
    if($bibls:subject != '') then 
        concat("collection('",$global:data-root,"')//tei:idno[.='",$bibls:subject,"']/ancestor::tei:body/descendant::tei:bibl[child::tei:ptr]")
    else ()  
};

(:~     
 : Build query string to pass to search.xqm 
:)
declare function bibls:query-string() as xs:string? { 
if($bibls:subject != '') then bibls:subject()
else
 concat("collection('",$global:data-root,"/bibl/tei')//tei:body",
    bibls:keyword(),
    bibls:title(),
    bibls:author(),
    bibls:pub-place(),
    bibls:publisher(),
    bibls:date(),
    bibls:idno()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function bibls:search-string(){
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
        return 
            if(request:get-parameter($parameter, '') != '') then
                if($parameter = 'q') then 
                    (<span class="param">Keyword: </span>,<span class="match">{common:clean-string($bibls:q)}</span>)
                else if ($parameter = 'author') then 
                    (<span class="param">Author/Editor: </span>,<span class="match">{common:clean-string($bibls:author)}</span>)
                else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{common:clean-string(request:get-parameter($parameter, ''))}</span>)    
            else ()               
};


(:~
 : Builds advanced search form for persons
 :)
declare function bibls:search-form() {   
<form method="get" action="search.html" class="form-horizontal" role="form">
    <div class="well well-small">
        <div><p><em>Wild cards * and ? may be used to optimize search results.
        Wild cards may not be used at the beginning of a word, as it hinders search speed.</em></p></div>
        <div class="well well-small search-inner well-white">
        <!-- Keyword -->
            <div class="form-group">            
                <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="q" name="q" class="form-control" placeholder="Any word in citation"/>
                </div>
            </div> 
            <hr/>         
            <div class="form-group">            
                <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="title" name="title" class="form-control"  placeholder="Title of article, journal, book, or series"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="author" class="col-sm-2 col-md-3  control-label">Author/Editor: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="author" name="author" class="form-control" placeholder="First Last or Last, First"/>
                </div>
            </div>  
            <div class="form-group">            
                <label for="pub-place" class="col-sm-2 col-md-3  control-label">Publication Place: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="pub-place" name="pub-place" class="form-control" placeholder="First Last or Last, First"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="publisher" class="col-sm-2 col-md-3  control-label">Publisher: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="publisher" name="publisher" class="form-control" placeholder="Publisher Name"/>
                </div>
            </div>   
            <div class="form-group">            
                <label for="date" class="col-sm-2 col-md-3  control-label">Date: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="date" name="date" class="form-control" placeholder="Year as YYYY"/>
                </div>
            </div>   
            <hr/>
            <div class="form-group">            
                <label for="idno" class="col-sm-2 col-md-3  control-label">Id Number: </label>
                <div class="col-sm-10 col-md-2 ">
                    <input type="text" id="idno" name="idno" class="form-control"  placeholder="Ex: 3490"/>
                </div>
            </div> 
        </div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>
</form>
};