xquery version "3.0";

module namespace places="http://syriaca.org/places";
import module namespace common="http://syriaca.org/common" at "common.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $places:q {request:get-parameter('q', '')};
declare variable $places:p {request:get-parameter('p', '')};
declare variable $places:type {request:get-parameter('type', '')};

declare variable $places:loc {request:get-parameter('loc', '')};
declare variable $places:lat {request:get-parameter('lat', '')};
declare variable $places:long {request:get-parameter('long', '')};

declare variable $places:e {request:get-parameter('e', '')};
declare variable $places:eds {request:get-parameter('eds', '')};
declare variable $places:ede {request:get-parameter('ede', '')};

declare variable $places:a {request:get-parameter('a', '')};
declare variable $places:ads {request:get-parameter('ads', '')};
declare variable $places:ade {request:get-parameter('ade', '')};

declare variable $places:c {request:get-parameter('c', '')};
declare variable $places:cds {request:get-parameter('cds', '')};
declare variable $places:cde {request:get-parameter('cde', '')};

declare variable $places:exist {request:get-parameter('exist', '')};
declare variable $places:existds {request:get-parameter('existds', '')};
declare variable $places:existde {request:get-parameter('existde', '')};

declare variable $places:en {request:get-parameter('en', '')};
declare variable $places:syr {request:get-parameter('syr', '')};
declare variable $places:ar {request:get-parameter('ar', '')};

(:~
 : Build full-text keyword search over all tei:place data
 : @q full text query
 descendant-or-self::* or . testing which is most correct
 
:)
declare function places:keyword(){
    if(exists($places:q) and $places:q != '') then concat("[ft:query(.,'",common:clean-string($places:q),"',common:options()) or ft:query(descendant::tei:placeName,'",common:clean-string($places:q),"',common:options()) or ft:query(descendant::tei:persName,'",common:clean-string($places:q),"',common:options()) or ft:query(ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:title,'",common:clean-string($places:q),"',common:options()) or ft:query(descendant::tei:desc,'",common:clean-string($places:q),"',common:options())]")
    else ''    
};

(:~
 : Build full-text keyword search over all tei:placeName data
 : @p full text query
:)
declare function places:place-name(){
    if(exists($places:p) and $places:p != '') then concat("[ft:query(descendant::tei:place/tei:placeName,'",common:clean-string($places:p),"',common:options())]")
    else ''    
};

(:~
 : Build range search on tei:place/@type data
 : @type full text query
:)
declare function places:type(){
    if(exists($places:type) and $places:type != '') then string(concat("[descendant::tei:place/@type = '",common:clean-string($places:type),"']"))
    else '' 
};

(:~
 : Build full-text search on tei:place/tei:location data
 : @loc full text query
 : NOTE: need to understand location search better. 
:)
declare function places:location(){
    if(exists($places:loc) and $places:loc != '') then concat("[ft:query(descendant::tei:place/tei:location,'",common:clean-string($places:loc),"',common:options())]")
    else ''
};

(:~
 : Build full-text search on tei:event[@type != attestation] data
 NOTE: will probably have to build this into the date range, so they hold together as one AND predicate
 : @e full text query
:)
declare function places:event(){
    if(exists($places:e) and $places:e != '') then concat("[ft:query(descendant::tei:place/tei:event[@type != 'attestation' or not(@type)],'",common:clean-string($places:e),"',common:options())]")
    else ''
};

(:~
 : Build date range for event 
 : tei:event[@type != attestation]
 : @eds event start range index
 : @ede event end range index
             concat('[descendant::tei:event[@type != "attestation" or not(@type)][(@syriaca-computed-start gt "',places:do-date($places:eds),'" and @syriaca-computed-end lt "',places:do-date($places:ede),'") or (@syriaca-computed-start gt "',places:do-date($places:eds),'" and not(@syriaca-computed-end))]]')
             concat('[descendant::tei:event[@type != "attestation" or not(@type)][@syriaca-computed-start gt "',places:do-date($places:eds),'"]]')
:)
declare function places:event-dates(){
    if(exists($places:eds) and $places:eds != '') then 
        if(exists($places:ede) and $places:ede != '') then 
            concat("[descendant::tei:event[@type != 'attestation' or not(@type)]
            [(
            @syriaca-computed-start gt 
                '",places:do-date($places:eds),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:ede),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:eds),"' 
                and 
                not(exists(@syriaca-computed-end)))]]")
        else 
            concat("[descendant::tei:event[@type != 'attestation' or not(@type)][@syriaca-computed-start gt '",places:do-date($places:eds),"' or @syriaca-computed-end gt '",places:do-date($places:eds),"']]")
    else if (exists($places:ede) and $places:ede != '') then 
        concat("[descendant::tei:event[@type != 'attestation' or not(@type)][@syriaca-computed-end lt '",places:do-date($places:ede),"' or @syriaca-computed-start lt '",places:do-date($places:ede),"' and not(@syriaca-computed-end)]]")
    else ''
};

(:~
 : Build full-text search on tei:event[@type = attestation] data
 : @e full text query
:)
declare function places:attestation(){
    if(exists($places:a) and $places:a != '') then concat("[ft:query(descendant::tei:place/tei:event[@type = 'attestation'],'",common:clean-string($places:a),"',common:options())]")
    else ''
};

(:~
 : Build date range for attestation
 : tei:event[@type = attestation]
 : @ads attestation start range index
 : @ade attestation end range index
:)
declare function places:attestation-dates(){
    if(exists($places:ads) and $places:ads != '') then 
        if(exists($places:ade) and $places:ade != '') then 
            concat("[descendant::tei:event[@type = 'attestation']
            [(
            @syriaca-computed-start gt 
                '",places:do-date($places:ads),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:ade),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:ads),"' 
                and 
                not(exists(@syriaca-computed-end)))]]")
        else 
            concat("[descendant::tei:event[@type = 'attestation'][@syriaca-computed-start gt '",places:do-date($places:ads),"' or @syriaca-computed-end gt '",places:do-date($places:ads),"']]")
    else if (exists($places:ade) and $places:ade != '') then 
        concat("[descendant::tei:event[@type = 'attestation'][@syriaca-computed-end lt '",places:do-date($places:ade),"' or @syriaca-computed-start lt '",places:do-date($places:ade),"' and not(@syriaca-computed-end)]]")
    else ''
};

(:~
 : Build full-text search on tei:state[@type = confession] data
 : @e full text query
:)
declare function places:confession(){
    if(exists($places:c) and $places:c != '') then 
        if(exists($places:cds) and $places:cds != '' or exists($places:cde) and $places:cde != '') then 
            concat("[descendant::tei:state[@type = 'confession'][matches(tei:label,'",$places:c,"') and ",places:confession-text-w-dates(),"]]") 
        else concat("[matches(descendant::tei:state[@type = 'confession']/tei:label,'",$places:c,"')]")
    else if(exists($places:cds) and $places:cds != '' or exists($places:cde) and $places:cde != '') then places:confession-dates()
    else ''
};

(:~
 : Build date range for confession
 : tei:state[@type = confession]
 : @cds confession start range index
 : @cde confession end range index
concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',places:do-date($places:cde),'"]]')
:)
declare function places:confession-dates(){
if(exists($places:cds) and $places:cds != '') then 
        if(exists($places:cde) and $places:cde != '') then 
            concat("[descendant::tei:state[@type = 'confession']
            [(
            @syriaca-computed-start gt 
                '",places:do-date($places:cds),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:cde),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:cds),"' 
                and 
                not(exists(@syriaca-computed-end)))]]")
        else 
            concat("[descendant::tei:state[@type = 'confession'][@syriaca-computed-start gt '",places:do-date($places:cds),"' or @syriaca-computed-end gt '",places:do-date($places:cds),"']]")
    else if (exists($places:cde) and $places:cde != '') then 
        concat("[descendant::tei:state[@type = 'confession'][@syriaca-computed-end lt '",places:do-date($places:cde),"' or @syriaca-computed-start lt '",places:do-date($places:cde),"' and not(@syriaca-computed-end)]]")
    else ''
};

(:~
 : Build date range for confession with confession text
 : tei:state[@type = confession]
 : @cds confession start range index
 : @cde confession end range index
concat('[descendant::tei:state[@type = "confession"][@syriaca-computed-end lt "',places:do-date($places:cde),'"]]')
:)
declare function places:confession-text-w-dates(){
if(exists($places:cds) and $places:cds != '') then 
        if(exists($places:cde) and $places:cde != '') then 
            concat("(
            (@syriaca-computed-start gt 
                '",places:do-date($places:cds),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:cde),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:cds),"' 
                and 
                not(exists(@syriaca-computed-end))
                )")
        else 
            concat("(@syriaca-computed-start gt '",places:do-date($places:cds),"') or (@syriaca-computed-end gt '",places:do-date($places:cds),"')")
    else if (exists($places:cde) and $places:cde != '') then 
        concat("((@syriaca-computed-end lt '",places:do-date($places:cde),"') or (@syriaca-computed-start lt '",places:do-date($places:cde),"' and not(@syriaca-computed-end)))")
    else ''
};

(:~
 : Build full-text search on tei:state[@type = ‘existence’] data
 : @e full text query
:)
declare function places:existence(){
    if(exists($places:exist) and $places:exist != '') then concat("[ft:query(descendant::tei:state[@type = 'existence'],'",common:clean-string($places:exist),"',common:options())]")
    else ''
};

(:~
 : Build date range for existence
 : tei:state[@type = existence]
 : @existds confession start range index
 : @existde confession end range index
:)
declare function places:existence-dates(){
if(exists($places:existds) and $places:existds != '') then 
        if(exists($places:existde) and $places:existde != '') then 
            concat("[descendant::tei:state[@type = 'existence']
            [(
            @syriaca-computed-start gt 
                '",places:do-date($places:existds),"' 
                and @syriaca-computed-end lt 
                '",places:do-date($places:existde),"'
                ) or (
                @syriaca-computed-start gt 
                '",places:do-date($places:existds),"' 
                and 
                not(exists(@syriaca-computed-end)))]]")
        else 
            concat("[descendant::tei:state[@type = 'existence'][@syriaca-computed-start gt '",places:do-date($places:existds),"' or @syriaca-computed-end gt '",places:do-date($places:existds),"']]")
    else if (exists($places:existde) and $places:existde != '') then 
        concat("[descendant::tei:state[@type = 'existence'][@syriaca-computed-end lt '",places:do-date($places:existde),"' or @syriaca-computed-start lt '",places:do-date($places:existde),"' and not(@syriaca-computed-end)]]")
    else ''
};

(:~
 : Function to cast dates strings from url to xs:date
 : Tests string length, may need something more sophisticated to test dates, 
 : or form validation via js before submit. 
 : @param $date passed to function from parent function
:)
declare function places:do-date($date){
let $date-format := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                    else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                    else if(string-length($date) eq 3) then concat('0',string($date),'-01-01')
                    else if(string-length($date) eq 2) then concat('00',string($date),'-01-01')
                    else if(string-length($date) eq 1) then concat('000',string($date),'-01-01')
                    else string($date)
let $final-date := xs:date($date-format) 
return $final-date
};

(:~
 : Limit by English language
 :)
declare function places:limit-by-lang-en(){
    if(exists($places:en) and $places:en != '') then concat("[descendant::tei:place/child::*/@xml:lang = '",$places:en,"']")
    else ''
};

(:~
 : Limit by Syriac language
 :)
declare function places:limit-by-lang-syr(){
    if(exists($places:syr) and $places:syr != '') then concat("[descendant::tei:place/child::*/@xml:lang = '",$places:syr,"']")
    else ''
};

(:~
 : Limit by Arabic language
 :)
declare function places:limit-by-lang-ar(){
    if(exists($places:ar) and $places:ar != '') then concat("[descendant::tei:place/child::*/@xml:lang = '",$places:ar,"']")
    else ''
};

(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
:)
declare function places:query-string() as xs:string?{
    concat("collection('",$global:data-root,"/places/tei')//tei:body",
    places:keyword(),
    places:type(),
    places:place-name(),
    places:location(),
    places:event(),places:event-dates(),
    places:attestation(), places:attestation-dates(), 
    places:existence(),places:existence-dates(),
    places:confession(),
    common:related-places(),
    common:related-persons(),
    common:mentioned(),
    places:limit-by-lang-en(),places:limit-by-lang-syr(),places:limit-by-lang-ar()
    )
};

(:~
 : Build search parameter string for search results page
:)
declare function places:search-string(){
<span xmlns="http://www.w3.org/1999/xhtml">
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = 'start' or $parameter = 'sort-element') then ()
            else if($parameter = 'q') then 
                (<span class="param">Keyword: </span>,<span class="match">{$places:q}&#160; </span>)
            else if($parameter = 'p') then 
                (<span class="param">Place Name: </span>,<span class="match">{$places:p}&#160; </span>)
            else if($parameter = 'type') then 
                (<span class="param">Type: </span>,<span class="match">{$places:type}&#160; </span>)
            else if($parameter = 'loc') then 
                (<span class="param">Location: </span>,<span class="match">{$places:loc}&#160; </span>)
            else if($parameter = 'e') then 
                (<span class="param">Event: </span>,<span class="match">{$places:e}&#160; </span>)
            else if($parameter = 'eds') then 
                (<span class="param">Event Start Date: </span>,<span class="match">{$places:eds}&#160; </span>)
            else if($parameter = 'ede') then 
                (<span class="param">Event End Date: </span>,<span class="match">{$places:ede}&#160; </span>)
            else if($parameter = 'a') then 
                (<span class="param">Attestations: </span>,<span class="match">{$places:a}&#160; </span>)
            else if($parameter = 'ads') then 
                (<span class="param">Attestations Start Date: </span>,<span class="match">{$places:ads}&#160; </span>)
            else if($parameter = 'ade') then 
                (<span class="param">Attestations End Date: </span>,<span class="match">{$places:ade}&#160; </span>)
            else if($parameter = 'c') then 
                (<span class="param">Religious Communities: </span>,<span class="match">{$places:c}&#160; </span>)
            else if($parameter = 'cds') then 
                (<span class="param">Religious Communities Start Date: </span>,<span class="match">{$places:cds}&#160; </span>)
            else if($parameter = 'cde') then 
                (<span class="param">Religious Communities End Date: </span>,<span class="match">{$places:cde}&#160; </span>)            
            else if($parameter = 'existds') then 
                (<span class="param">Existence Start Date: </span>,<span class="match">{$places:existds}&#160; </span>)
            else if($parameter = 'existde') then 
                (<span class="param">Existence End Date: </span>,<span class="match">{$places:existde}&#160; </span>)        
            
            else if($parameter = 'en' and $places:en != '') then 
                (<span class="param">English </span>)  
            else if($parameter = 'syr' and $places:syr != '') then 
                (<span class="param">Syriac </span>)
            else if($parameter = 'ar' and $places:ar != '') then 
                (<span class="param">Arabic </span>)    
            else (<span class="param"> {replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
        else ())
        }
</span>                                            
};

declare function places:results-node($hit){
    let $root := $hit//tei:place   
    let $title-en := $root/tei:placeName[@syriaca-tags='#syriaca-headword'][contains(@xml:lang,'en')][1]
    let $title-syr := 
                    if($root/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr'][1]) then 
                        (<bdi dir="ltr" lang="en" xml:lang="en"><span> -  </span></bdi>,
                            <bdi dir="rtl" lang="syr" xml:lang="syr">
                                {$root/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='syr'][1]}
                            </bdi>)
                    else ''
    let $type := if($root/@type) then  
                    <bdi dir="ltr" lang="en" xml:lang="en"> ({string($root/@type)})</bdi>
                  else ''  
    let $id := substring-after($root/@xml:id,'place-')                        
    return
        <p style="font-weight:bold padding:.5em;">
            <a href="/place/{$id}.html">
                <bdi dir="ltr" lang="en" xml:lang="en">{$title-en}</bdi>
                {$type,$title-syr}
            </a>
        </p>
};

(:~
 : Builds advanced search form
 :)
declare function places:search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
             <button type="button" class="btn btn-info pull-right" data-toggle="collapse" data-target="#searchTips">
                Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span>
            </button>&#160;
            <xi:include href="../searchTips.html"/>
        <div class="well well-small search-inner well-white">
            <div class="row">
                <div class="col-md-7" style="border-right:1px solid #ccc;">
                <!-- Keyword -->
                 <div class="form-group">
                    <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                    <div class="col-sm-10 col-md-9 ">
                       <div class="input-group">
                        <input type="text" id="qs" name="q" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                <ul class="dropdown-menu">
                                    <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="qs">Syriac Phonetic</a></li>                                
                                    <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="qs">Syriac Standard</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Arabic (101)" data-keyboard-id="qs">Arabic Mod. Standard</a></li>
                                    <li><a href="#" class="keyboard-select" id="qwerty" data-keyboard-id="qs">English QWERTY</a></li>                                        
                                    <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="qs">Greek Mod. Standard</a></li>
                                    <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="qs">Russian Mod. Standard</a></li>
                                </ul>
                            </div>
                    </div> 
                    </div>
                  </div>
                    <!-- Place Name-->
                  <div class="form-group">
                    <label for="p" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                    <div class="col-sm-10 col-md-9 ">
                       <div class="input-group">
                            <input type="text" id="p" name="p" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                    <ul class="dropdown-menu">
                                        <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="p">Syriac Phonetic</a></li>                                    
                                        <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="p">Syriac Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Arabic (101)" data-keyboard-id="p">Arabic Mod. Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="qwerty" data-keyboard-id="p">English QWERTY</a></li>       
                                        <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="p">Greek Mod. Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="p">Russian Mod. Standard</a></li>
                                    </ul>
                            </div>
                        </div> 
                    </div>
                  </div>
                    <!-- Location --> 
                    <div class="form-group">
                        <label for="loc" class="col-sm-2 col-md-3  control-label">Location: </label>
                        <div class="col-sm-10 col-md-9 ">
                           <div class="input-group">
                                <input type="text" id="loc" name="loc" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                    <ul class="dropdown-menu">
                                        <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="loc">Syriac Phonetic</a></li>                                    
                                        <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="loc">Syriac Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Arabic (101)" data-keyboard-id="loc">Arabic Mod. Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="qwerty" data-keyboard-id="loc">English QWERTY</a></li>                                        
                                        <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="loc">Greek Mod. Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="loc">Russian Mod. Standard</a></li>
                                    </ul>
                            </div>
                            </div>                         
                        </div>
                    </div>
                    <hr/>
                    <div class="form-group">
                        <label for="e" class="col-sm-2 col-md-3  control-label">Events: </label>
                        <div class="col-sm-10 col-md-9 ">
                           <div class="input-group">
                            <input type="text" id="e" name="e" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                    <ul class="dropdown-menu">
                                        <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="e">Syriac Phonetic</a></li>                                    
                                        <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="e">Syriac Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Arabic (101)" data-keyboard-id="e">Arabic Mod. Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="qwerty" data-keyboard-id="e">English QWERTY</a></li>                                         
                                        <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="e">Greek Mod. Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="e">Russian Mod. Standard</a></li>
                                    </ul>
                            </div>
                            </div>                              
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="eds" class="col-sm-2 col-md-3  control-label">Dates: </label>
                        <div class="col-sm-10 col-md-9 form-inline">
                            <input type="text" id="eds" name="eds" placeholder="Start Date" class="form-control"/>&#160;
                            <input type="text" id="ede" name="ede" placeholder="End Date" class="form-control"/>
                            <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                        </div>
                    </div>
                     <hr/>
                     <!-- Attestations -->
                     <div class="form-group">
                        <label for="a" class="col-sm-2 col-md-3  control-label">Attestations: </label>
                        <div class="col-sm-10 col-md-9 ">
                           <div class="input-group">
                            <input type="text" id="a" name="a" class="form-control keyboard"/>
                            <div class="input-group-btn">
                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                    </button>
                                    <ul class="dropdown-menu">
                                        <li><a href="#" class="keyboard-select" id="syriac-phonetic" data-keyboard-id="a">Syriac Phonetic</a></li>
                                        <li><a href="#" class="keyboard-select" id="syriac-standard" data-keyboard-id="a">Syriac Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Arabic (101)" data-keyboard-id="a">Arabic Mod. Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="qwerty" data-keyboard-id="a">English QWERTY</a></li>                                        
                                        <li><a href="#" class="keyboard-select" id="ms-Greek" data-keyboard-id="a">Greek Mod. Standard</a></li>
                                        <li><a href="#" class="keyboard-select" id="ms-Russian" data-keyboard-id="a">Russian Mod. Standard</a></li>
                                    </ul>
                            </div>
                            </div>                             
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="ads" class="col-sm-2 col-md-3  control-label">Dates: </label>
                        <div class="col-sm-10 col-md-9 form-inline">
                            <input type="text" id="ads" name="ads" placeholder="Start Date" class="form-control"/>&#160;
                            <input type="text" id="ade" name="ade" placeholder="End Date" class="form-control"/>
                            <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                        </div>
                    </div>
                     <hr/>
                     <!-- Confessions -->
                      <div class="form-group">
                        <label for="c" class="col-sm-2 col-md-3 control-label">Religious Communities: </label>
                        <div class="col-sm-10 col-md-9">
                            <select type="text" id="c" name="c" class="form-control">
                                <option value="">-- Select --</option>
                                {for $confession in doc('/db/apps/srophe/documentation/confessions.xml')//tei:item
                                 return 
                                 <option value="{$confession/child::tei:label}">
                                 {
                                    (for $confession-parent in $confession/ancestor::tei:item return '&#160;',
                                     $confession/child::tei:label)
                                 }
                                 </option>
                                }
                            </select>
                        </div>
                      </div>
                    <div class="form-group">
                        <label for="cds" class="col-sm-2 col-md-3 control-label">Dates: </label>
                        <div class="col-sm-10 col-md-9 form-inline">
                            <input type="text" id="cds" name="cds" placeholder="Start Date" class="form-control"/>&#160;
                            <input type="text" id="cde" name="cde" placeholder="End Date" class="form-control"/>
                            <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                        </div>
                    </div>
                     <hr/>
                     <!-- Existence -->
                    <div class="form-group">
                        <label for="existds" class="col-sm-2 col-md-3 control-label">Existence Dates: </label>
                        <div class="col-sm-10 col-md-9 form-inline">
                            <input type="text" id="existds" name="existds" placeholder="Start Date" class="form-control"/>&#160;
                            <input type="text" id="existde" name="existde" placeholder="End Date" class="form-control"/>
                            <p class="hint" style="margin:.5em; color: grey; font-style:italic;">* Dates should be entered as YYYY or YYYY-MM-DD</p>
                        </div>
                    </div>
            <!-- Associated Places-->
            <div class="form-group">            
                <label for="related-place" class="col-sm-2 col-md-3  control-label">Related Places: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="related-place" name="related-place" placeholder="Related Places" class="form-control"/>&#160;
                    <p class="hint small">* Enter syriaca.org URI, ex: http://syriaca.org/place/78</p>
                </div>
            </div>
            <!-- Related persons-->
            <div class="form-group">            
                <label for="related-persons" class="col-sm-2 col-md-3  control-label">Related Persons: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="related-persons" name="related-persons" class="form-control" placeholder="Related Persons"/>
                    <p class="hint small">* Enter syriaca.org URI, ex: http://syriaca.org/person/13</p>
                </div>
            </div>
            <!--Associated Texts:-->
            <div class="form-group">            
                <label for="mentioned" class="col-sm-2 col-md-3  control-label">Related Works: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="mentioned" name="mentioned" class="form-control" placeholder="Related Works"/>
                    <p class="hint small">* Enter syriaca.org URI, ex: http://syriaca.org/work/429</p>
                </div>
            </div>                    
                </div>
                <div class="col-md-5">
                      <!-- Place Type -->
                    <div style="margin-top:1em; padding-left:.5em;">
                        <label class="control-label">Place Type: </label>
                            <select name="type" id="type" class="input-medium form-control">
                                <option value="">- Select -</option>
                                <option value="building">building</option>
                                <option value="church">church</option>
                                <option value="diocese">diocese</option>
                                <option value="fortification">fortification</option>
                                <option value="island">island</option>
                                <option value="madrasa">madrasa</option>
                                <option value="monastery">monastery</option>
                                <option value="mosque">mosque</option>
                                <option value="mountain">mountain</option>
                                <option value="open-water">open-water</option>
                                <option value="parish">parish</option>
                                <option value="province">province</option>
                                <option value="quarter">quarter</option>
                                <option value="region">region</option>
                                <option value="river">river</option>
                                <option value="settlement">settlement</option>
                                <option value="state">state</option>
                                <option value="synagogue">synagogue</option>
                                <option value="temple">temple</option>
                                <option value="unknown">unknown</option>
                            </select>
                        <hr/>
                    <!-- Language -->
                       <label class="control-label">Language: </label>
                        <div class="col-md-offset-1">
                            <input type="checkbox" name="en" value="en"/> English<br/>
                            <input type="checkbox" name="ar" value="ar"/> Arabic<br/>
                            <input type="checkbox" name="syr" value="syr"/> Syriac<br/>
                        </div>

                    </div>
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
