xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Browse by type
 :
 : @see lib/geojson.xqm for map generation
 :)

module namespace browse="http://syriaca.org/browse";

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace common="http://syriaca.org/common" at "search/common.xqm";
import module namespace facets="http://syriaca.org/facets" at "lib/facets.xqm";
import module namespace ev="http://syriaca.org/events" at "lib/events.xqm";
import module namespace rel="http://syriaca.org/related" at "lib/get-related.xqm";
import module namespace rec="http://syriaca.org/short-rec-view" at "short-rec-view.xqm";
import module namespace geo="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace templates="http://exist-db.org/xquery/templates";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:~ 
 : Parameters passed from the url
 : @param $browse:coll selects collection (persons/places ect) for browse.html 
 : @param $browse:type selects doc type filter eg: place@type person@ana
 : @param $browse:view selects language for browse display
 : @param $browse:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $browse:coll {request:get-parameter('coll', '')};
declare variable $browse:type {request:get-parameter('type', '')}; 
declare variable $browse:view {request:get-parameter('view', '')};
declare variable $browse:sort {request:get-parameter('sort', '')};
declare variable $browse:date {request:get-parameter('date', '')};
declare variable $browse:fq {request:get-parameter('fq', '')};
declare variable $browse:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $browse:perpage {request:get-parameter('perpage', 25) cast as xs:integer};

(:~
 : Build browse path for evaluation 
 : Uses $collection to build path to appropriate data set 
 : If no $collection parameter is present data and all subdirectories will be searched.
 : @param $collection collection name passed from html, should match data subdirectory name
:)
declare function browse:get-all($node as node(), $model as map(*), $collection as xs:string?){
let $browse-path := 
    if($collection = ('persons','sbd','saints','q','authors')) then concat("collection('",$global:data-root,"/persons/tei')",browse:get-coll($collection),browse:get-syr())
    else if($collection = 'places') then concat("collection('",$global:data-root,"/places/tei')",browse:get-coll($collection),browse:get-syr())
    else if($collection = 'bhse') then concat("collection('",$global:data-root,"/works/tei')",browse:get-coll($collection),browse:get-syr())
    else if($collection = 'bibl') then concat("collection('",$global:data-root,"/bibl/tei')",browse:get-syr())
    else if($collection = 'spear') then concat("collection('",$global:data-root,"/spear/tei')//tei:div",facets:facet-filter())
    else if($collection = 'manuscripts') then concat("collection('",$global:data-root,"/manuscripts/tei')//tei:TEI")
    else if(exists($collection)) then concat("collection('",$global:data-root,xs:anyURI($collection),"')",browse:get-coll($collection),browse:get-syr())
    else concat("collection('",$global:data-root,"')",browse:get-coll($collection),browse:get-syr())
return 
    map{"browse-data" := util:eval($browse-path)}      
};

declare function browse:parse-collections($collection as xs:string?) {
    if($collection = ('persons','sbd')) then 'The Syriac Biographical Dictionary'
    else if($collection = ('saints','q')) then 'Qadishe: A Guide to the Syriac Saints'
    else if($collection = 'authors' ) then 'A Guide to Syriac Authors'
    else if($collection = 'bhse' ) then 'Bibliotheca Hagiographica Syriaca Electronica'
    else if($collection = ('places','The Syriac Gazetteer')) then 'The Syriac Gazetteer'
    else if($collection = ('spear','SPEAR: Syriac Persons, Events, and Relations')) then 'SPEAR: Syriac Persons, Events, and Relations'
    else if($collection != '' ) then $collection
    else ()
};

(:~
 : Filter titles by subcollection
 : Used by persons as there are several subcollections within SBD
 : @param $collection passed from html template
:)
declare function browse:get-coll($collection) as xs:string?{
if(not(empty($collection))) then
    concat("//tei:title[. = '",browse:parse-collections($collection),"']/ancestor::tei:TEI")    
else '//tei:TEI'    
};

(:~
 : Return only Syriac titles 
 : Based on Syriac headwords 
 : @param $browse:view
:)
declare function browse:get-syr() as xs:string?{
    if($browse:view = 'syr') then
        "[descendant::*[contains(@syriaca-tags,'#syriaca-headword')][@xml:lang = 'syr']]"
    else ()    
};

(:~
 : Matches English letters and their equivalent letters as established by Syriaca.org
 : @param $browse:sort indicates letter for browse
 :)
declare function browse:get-sort(){
    if(exists($browse:sort) and $browse:sort != '') then
        if($browse:sort = 'A') then '(A|a|ẵ|Ẵ|ằ|Ằ|ā|Ā)'
        else if($browse:sort = 'D') then '(D|d|đ|Đ)'
        else if($browse:sort = 'S') then '(S|s|š|Š|ṣ|Ṣ)'
        else if($browse:sort = 'E') then '(E|e|ễ|Ễ)'
        else if($browse:sort = 'U') then '(U|u|ū|Ū)'
        else if($browse:sort = 'H') then '(H|h|ḥ|Ḥ)'
        else if($browse:sort = 'T') then '(T|t|ṭ|Ṭ)'
        else if($browse:sort = 'I') then '(I|i|ī|Ī)'
        else if($browse:sort = 'O') then '(O|Ō|o|Œ|œ)'
        else $browse:sort
    else '(A|a|ẵ|Ẵ|ằ|Ằ|ā|Ā)'
};

(:~
 : Strips english titles of non-sort characters as established by Syriaca.org
 : @param $titlestring 
 :)
declare function browse:build-sort-string($titlestring as xs:string*) as xs:string* {
    replace(replace(replace(replace($titlestring,'^\s+',''),'^al-',''),'[‘ʻʿ]',''),'On ','')
};

(:~
 : ABC sort on English titles
:)
declare function browse:en-title-filter($node as node(), $model as map(*)){
    $model("browse-data")//tei:title[@level='a'][parent::tei:titleStmt][matches(substring(browse:build-sort-string(text()),1,1),browse:get-sort())]
};

(:~
 : Syriac search, only for records with syr headwords 
:)
declare function browse:syr-title-filter($node as node(), $model as map(*)){
    $model("browse-data")//tei:body[contains($browse:sort, substring(string-join(descendant::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'syr')][1]/descendant-or-self::*/text(),' '),1,1))]
};

(: NOTE, pare-collections alread does this, just pass in $browse:type:)
declare function browse:browse-pers-types(){
    if($browse:type = 'saint') then 'Qadishe: A Guide to the Syriac Saints'
    else if($browse:type = ('author')) then 'A Guide to Syriac Authors'
    else ()
};

(: Formats end dates queries for searching :)
declare function browse:get-end-date(){
let $date := substring-after($browse:date,'-')
return
    if($browse:date = '0-100') then '0001-01-01'
    else if($browse:date = '2000-') then '2100-01-01'
    else if(matches($date,'\d{1}')) then concat('000',$date,'-01-01')
    else if(matches($date,'\d{2}')) then concat('00',$date,'-01-01')
    else if(matches($date,'\d{3}')) then concat('0',$date,'-01-01')
    else if(matches($date,'\d{4}')) then concat($date,'-01-01')
    else '0100-01-01'
};

(: Formats end start queries for searching :)
declare function browse:get-start-date(){
let $date := substring-before($browse:date,'-')
return 
    if(matches($date,'0')) then '0001-01-01'
    else if($browse:date = '2000-') then '2000-01-01'
    else if(matches($date,'\d{1}')) then concat('000',$date,'-01-01')
    else if(matches($date,'\d{2}')) then concat('00',$date,'-01-01')
    else if(matches($date,'\d{4}')) then concat($date,'-01-01')
    else '0001-01-01'
};

declare function browse:narrow-by-type($node as node(), $model as map(*), $collection){
    if($browse:type != '') then 
        if($collection = ('persons','saints','authors')) then
            if($browse:type != '') then 
                if($browse:type = 'unknown') then $model("browse-data")//tei:person[not(ancestor::tei:TEI/descendant::tei:title[@level='m'][. = ('A Guide to Syriac Authors','Qadishe: A Guide to the Syriac Saints')])]
                    else $model("browse-data")//tei:person[ancestor::tei:TEI/descendant::tei:title[@level='m'][. = browse:browse-pers-types()]]
                else ()
            else   
                if($browse:type != '') then 
                    $model("browse-data")//tei:place[contains(@type,$browse:type)]
                else $model("browse-data")
    else () 
};

declare function browse:narrow-by-date($node as node(), $model as map(*)){
    if($browse:date != '') then 
        if($browse:date = 'BC dates') then 
            $model("browse-data")/self::*[starts-with(descendant::*/@syriaca-computed-start,"-") or starts-with(descendant::*/@syriaca-computed-end,"-")]
        else
            $model("browse-data")//tei:body[descendant::*[@syriaca-computed-start lt browse:get-end-date() and @syriaca-computed-start gt  browse:get-start-date()]] 
            | $model("browse-data")//tei:body[descendant::*[@syriaca-computed-end gt browse:get-start-date() and @syriaca-computed-start lt browse:get-end-date()]]
    else () 
};

declare function browse:spear-person($node as node(), $model as map(*)){
$model("browse-data")//tei:persName
 
  (:for $data in $model("browse-data")//tei:persName
  let $id := normalize-space($data[1]/@ref)
  let $connical := collection($global:data-root)//tei:idno[. = $id]
  let $name := if($connical) then $connical/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"][@xml:lang='en'][1]
                else if($data/text()) then $data/text()[1]
                else tokenize($id,'/')[last()]
  group by $person := $name
  order by $person
  return 
    for $pers-data in $person[1] 
    return ($data[1]):)
};

declare function browse:spear-place($node as node(), $model as map(*)){
  for $data in $model("browse-data")//tei:placeName
  let $id := normalize-space($data[1]/@ref)
  let $connical := collection($global:data-root)//tei:idno[. = $id]
  let $name := if($connical) then $connical/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"][@xml:lang='en'][1]
                else if($data/text()) then $data/text()[1]
                else tokenize($id,'/')[last()]
  group by $person := $name
  order by $person
  return 
    for $pers-data in $person[1] 
    return $data[1]
};

declare function browse:spear-event($node as node(), $model as map(*)){
  for $data in $model("browse-data")//tei:event[parent::tei:listEvent]
  return $data
  (:(spear:build-timeline($node,$model,'events'),spear:build-events-panel($node,$model):)
};

declare function browse:spear-keyword($node as node(), $model as map(*)){
  for $data in $model("browse-data")//tei:event[parent::tei:listEvent]
  return $data
};

declare function browse:narrow-spear($node as node(), $model as map(*)){
let $data :=
    if($browse:view = 'person') then 
        browse:spear-person($node, $model)
    else if($browse:view = 'place') then 
        browse:spear-place($node, $model)
    else if($browse:view = 'event') then 
        browse:spear-event($node, $model)
    else if($browse:view = 'keyword') then   
        browse:spear-keyword($node, $model)
    else $model("browse-data")
return map{"browse-refine" := $data}
};

(:~
 : Evaluates additional browse parameters; type, date, abc, etc. 
 : Adds narrowed data set to new map
:)
declare function browse:get-narrow($node as node(), $model as map(*),$collection as xs:string*){
let $data := 
        if($browse:view='numeric') then $model("browse-data")
        else if($browse:view = 'type') then browse:narrow-by-type($node, $model, $collection)   
        else if($browse:view = 'date') then browse:narrow-by-date($node, $model)
        else if($browse:view = 'map') then $model("browse-data")
        else if($browse:view = 'syr') then browse:syr-title-filter($node, $model)
        else browse:en-title-filter($node, $model)
return
    map{"browse-refine" := $data}
};

(:
 : Set up browse page, select correct results function based on URI params
 : @param $collection passed from html 
:)
declare function browse:results-panel($node as node(), $model as map(*), $collection){
if($collection = 'spear') then  browse:spear-results-panel($node, $model)
else if($browse:view = 'type' or $browse:view = 'date') then
    (<div class="col-md-4">{if($browse:view='type') then browse:browse-type($node,$model,$collection)  else browse:browse-date()}</div>,
     <div class="col-md-8">{
        if($browse:view='type') then
            if($browse:type != '') then 
                (<h3>{concat(upper-case(substring($browse:type,1,1)),substring($browse:type,2))}</h3>,
                 <div>{browse:get-data($node,$model,$collection)}</div>)
            else <h3>Select Type</h3>    
        else if($browse:view='date') then 
            if($browse:date !='') then 
                (<h3>{$browse:date}</h3>,
                 <div>{browse:get-data($node,$model,$collection)}</div>)
            else <h3>Select Date</h3>  
        else ()}</div>)
else if($browse:view = 'map') then browse:get-map($node, $model)
else 
    <div class="col-md-12">
        { (
        if(($browse:view = 'syr')) then (attribute dir {"rtl"}) else(),
        browse:browse-abc-menu(),
        <h3>{(
            if(($browse:view = 'syr')) then 
                (attribute dir {"rtl"}, attribute lang {"syr"}, attribute class {"label pull-right"}) 
            else attribute class {"label"},
                if($browse:sort != '') then $browse:sort else 'A')}</h3>,
        <div class="{if($browse:view = 'syr') then 'syr-list' else 'en-list'}">
            {browse:get-data($node,$model,$collection)}
        </div>
        )
        }
    </div>
};

declare function browse:spear-results-panel($node as node(), $model as map(*)){
 (
    if($browse:view = 'person' or $browse:view = 'place') then browse:browse-abc-menu() else(),
    if($browse:view = 'relations') then 
        <div class="col-md-12">
            <h3>Explore SPEAR Relationships</h3>
            <iframe id="iframe" src="../modules/d3xquery/build-html.xqm" width="100%" height="30000" scrolling="auto" frameborder="0" seamless="true"/>
        </div>
    else                 
    <div class="col-md-3">
        {
            if($browse:view = 'advanced') then () 
            else
                <div>
                    <h4>Narrow by Source Text</h4>
                    <span class="facets applied">
                        {
                            if($facets:fq) then facets:selected-facet-display()
                            else ()            
                        }
                    </span>
                    <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
                        <!-- BUILD into facets -->
                        <!--<li><a href="?filter=all" class="facet-label">All <span class="count">  ({count($model("browse-refine"))})</span></a></li>-->
                       {
                           let $facet-nodes := $model('browse-refine')
                           return 
                           <li>{facets:title($facet-nodes)}</li>
                       }
                    </ul>
                    {
                    if($browse:view = 'keywords') then 
                       (<h4>Narrow by Keyword</h4>,
                        <ul class="nav nav-tabs nav-stacked" style="margin-left:-1em;">
                            {
                               let $facet-nodes := $model('browse-refine')
                               let $facets := $facet-nodes//tei:event
                               return 
                               <li>{facets:keyword($facets)}</li>
                            }
                       </ul>)
                    else ()
                    }
                </div>
        }
          
    </div>,
     <div class="col-md-8">
        {
            if($browse:view = 'advanced') then
                <div class="container">
                    <h4>Advanced browse options: <a href="search.html?q=">see advanced search</a></h4>
                </div>      
            else if($browse:view = 'keyword') then 
                (<h3>Browse Factoids by Keywords</h3>,
                    <h4>Select a Source </h4>)
            else 
                browse:display-spear($node,$model) 
        }
    </div>)
};

declare function browse:get-map($node as node(), $model as map(*)){
    <div class="col-md-12 map-lg">
        {geo:build-google-map($model("browse-data")//tei:geo, '', '')}
    </div>
};

(:
 : Sorts and outputs results set
 : @param $coll from html template
:)
declare function browse:get-data($node as node(), $model as map(*), $collection as xs:string*) as node()*{
(
if($browse:view = 'map' or $browse:view = 'type') then
        if($model("browse-refine")//tei:geo) then
            <div class="map-sm inline-map well">{geo:build-map($model("browse-refine")//tei:geo, '', '')}</div>
        else ()        
else (),
for $data in $model("browse-refine")
let $rec-id := if($collection = 'spear') then 
    string($data/@uri) else tokenize(replace($data/descendant::tei:idno[starts-with(.,$global:base-uri)][1],'/tei|/source',''),'/')[last()]
let $en-title := 
             if($data/self::tei:title) then $data/text()
             else if($data/self::tei:div) then $data/text()
             else if($data/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][1]) then 
                 string-join($data/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][1]//text(),' ')
             else $data/ancestor::tei:TEI/descendant::tei:title[1]/text()               
let $syr-title := 
             if($data/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'syr')][1]) then
                string-join($data/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'syr')][1]//text(),' ')
             else 'NA'
let $title := if($browse:view = 'syr') then $syr-title else $en-title
let $browse-title := browse:build-sort-string($title)
order by 
    if($browse:view = 'numeric') then xs:integer($rec-id) 
    else $browse-title collation "?lang=en&lt;syr&amp;decomposition=full"             
return
(: Temp patch for manuscripts  :)
    if($collection = "manuscripts") then 
        let $title := $data/descendant::tei:titleStmt/tei:title[1]/text()
        let $id := $data/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][2]/text()
        return 
            <div>
                <a href="manuscript.html?id={$id}">{$title}</a>
            </div>
    else 
        if($collection = 'spear') then $data (:rec:display-recs-short-view($data,''):) 
        else if($browse:view = 'syr') then 
            rec:display-recs-short-view($data,'syr') 
        else rec:display-recs-short-view($data/ancestor::tei:TEI,'')
) 
};

declare function browse:spear-person($nodes){
let $ids := distinct-values($nodes/@ref)
return
<div>
    <h3>Factoids ({count($ids)})</h3>
    {
                for $data in $nodes
                let $id := normalize-space($data[1]/@ref)
                let $connical := collection($global:data-root)//tei:idno[. = $id]
                let $name := if($connical) then $connical/ancestor::tei:body/descendant::*[@syriaca-tags="#syriaca-headword"][@xml:lang='en'][1]
                             else tokenize($id,'/')[last()]
                group by $person := $name
                order by $person
                return  
                        for $pers-data in $person[1] 
                        return 
                        <div>
                            <a href="factoid.html?id={$id}">{$data[1]}</a>
                        </div>
    }
</div>
};

(: add paging 
<h3>{if($browse:view) then $browse:view else 'Factoids'} ({count($data)})</h3>
:)
declare function browse:display-spear($node as node(), $model as map(*)){
let $data := $model("browse-refine")
return 
<div>
    <div>
        {
            if($browse:view = 'event') then 
                (ev:build-timeline($data,'events'), ev:build-events-panel($data))
            else if($browse:view = 'person' or $browse:view = 'place') then 
                browse:spear-person($data)
            else 
            for $d in $data
            return rec:display-recs-short-view($d,'')
        }
    </div>
</div>
};

(:~
 : Browse Alphabetical Menus
:)
declare function browse:browse-abc-menu(){
    <div class="browse-alpha tabbable">
        <ul class="list-inline">
        {
            if(($browse:view = 'syr')) then  
                for $letter in tokenize('ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')
                return 
                    <li class="syr-menu" lang="syr"><a href="?view={$browse:view}&amp;sort={$letter}">{$letter}</a></li>
            else                
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', ' ')
                return
                    <li><a href="?view={$browse:view}&amp;sort={$letter}">{$letter}</a></li>

        }
        </ul>
    </div>
};

declare function browse:browse-type($node as node(), $model as map(*), $collection){  
    <ul class="nav nav-tabs nav-stacked">
        {
            if($collection = ('places','geo')) then 
                for $types in $model("browse-data")//tei:place
                    group by $place-types := $types/@type
                    order by $place-types ascending
                    return
                        <li> {if($browse:type = replace(string($place-types),'#','')) then attribute class {'active'} else '' }
                            <a href="?view=type&amp;type={$place-types}">
                            {if(string($place-types) = '') then 'unknown' else replace(string($place-types),'#|-',' ')}  <span class="count"> ({count($types)})</span>
                            </a> 
                        </li>
            else             
                 for $types in $model("browse-data")//tei:person
                 group by $pers-types := $types/@ana
                 order by $pers-types ascending
                 return
                     let $pers-types-labels := if($pers-types) then replace(string($pers-types),'#syriaca-','') else 'unknown'
                     return
                         <li>{if($browse:type = $pers-types-labels) then attribute class {'active'} else '' }
                             <a href="?view=type&amp;type={$pers-types-labels}">
                             {if(string($pers-types) = '') then 'unknown' else replace(string($pers-types),'#syriaca-','')}  <span class="count"> ({count($types)})</span>
                             </a>
                         </li>
        }
    </ul>

};

(:
 : Browse by date
 : Precomputed values
 : NOTE: would be nice to use facets, however, it is currently inefficient 
:)
declare function browse:browse-date(){
    <ul class="nav nav-tabs nav-stacked pull-left type-nav">
        {   
            let $all-dates := 'BC dates, 0-100, 100-200, 200-300, 300-400, 400-500, 500-600, 700-800, 800-900, 900-1000, 1100-1200, 1200-1300, 1300-1400, 1400-1500, 1500-1600, 1600-1700, 1700-1800, 1800-1900, 1900-2000, 2000-'
            for $date in tokenize($all-dates,', ')
            return
                    <li>{if($browse:date = $date) then attribute class {'active'} else '' }
                        <a href="?view=date&amp;date={$date}">
                            {$date}  <!--<span class="count"> ({count($types)})</span>-->
                        </a>
                    </li>
            }
    </ul>
};

(:~
 : Browse Tabs - Eng
 : Choose which functions to include with each browse. 
 : Note: should this be done with javascript? possibly. 
:)
declare  %templates:wrap function browse:build-tabs-en($node, $model){
    <li>{if(not($browse:view)) then attribute class {'active'} 
         else if($browse:view = 'en') then attribute class {'active'} 
         else '' }<a href="browse.html?view=en&amp;sort=A">English</a>
    </li>   
};

(:~
 : Browse Tabs - Syr
:)
declare  %templates:wrap function browse:build-tabs-syr($node, $model){
    <li>{if($browse:view = 'syr') then attribute class {'active'} 
         else '' }<a href="browse.html?view=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
    </li>   
};

(:~
 : Browse Tabs - Type  
:)
declare  %templates:wrap function browse:build-tabs-type($node, $model){
    <li>{if($browse:view = 'type') then attribute class {'active'}
         else '' }<a href="browse.html?view=type">Type</a>
    </li>
};

(:~
 : Browse Tabs - Map
:)
declare  %templates:wrap function browse:build-tabs-date($node, $model){
    <li>{if($browse:view = 'date') then attribute class {'active'} 
         else '' }<a href="browse.html?view=date">Date</a>
    </li>
};

(:~
 : Browse Tabs - Map
:)
declare  %templates:wrap function browse:build-tabs-map($node, $model){
    <li>{if($browse:view = 'map') then attribute class {'active'} 
         else '' }<a href="browse.html?view=map">Map</a>
    </li>
};

(:~
 : Browse Tabs - SPEAR
:)
declare  %templates:wrap function browse:build-tabs-spear($node, $model){    
    (<li>{if(not($browse:view)) then 
                attribute class {'active'} 
          else if($browse:view = 'sources') then 
                attribute class {'active'}
          else '' }<a href="browse.html?view=sources">Sources</a>
    </li>,
    <li>{if($browse:view = 'person') then 
                attribute class {'active'} 
        else '' }<a href="browse.html?view=person&amp;sort=all">Persons</a>
    </li>,
    <li>{if($browse:view = 'event') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=event">Events</a>
    </li>,
    <li>{
             if($browse:view = 'relations') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=relations">Relations</a>
    </li>,
    <li>{if($browse:view = 'place') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=place&amp;sort=all">Places</a>
    </li>,
    <li>{if($browse:view = 'keywords') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=keywords">Keywords</a>
    </li>,
    <li>{if($browse:view = 'advanced') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=advanced">Advanced Browse</a>
    </li>)
};
