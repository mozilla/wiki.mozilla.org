<?php

/**
 * Web-based API for executing semantic queries (#ask)
 *
 * @todo add some missing options to the semantic search (start, limit...)?
 *
 * @file
 * @ingroup SMWAskAPI
 * @author pierremz
 *
 */
if (!defined('MEDIAWIKI')) {
    exit(1);
}

require_once ( "$IP/includes/api/ApiBase.php" );

global $wgAPIModules;

/**
 * If set, this variable control which name the action will be available under, in
 * the API - default is 'ask'
 */
global $wgSMWAskAPI_ActionName;

if (!isset($wgSMWAskAPI_ActionName) || is_null($wgSMWAskAPI_ActionName)) {
    $wgSMWAskAPI_ActionName = 'ask';
}

$wgAPIModules[$wgSMWAskAPI_ActionName] = 'SMWAskAPI';

/**
 * Web-based API for executing semantic queries (#ask)
 *
 * @ingroup SMWWriter API
 * @author denny
 */
class SMWAskAPI extends ApiBase {

    // Parameters holding the querystring
    private static $PARAM_QUERY = 'q';
    // Parameters holding the printouts (ie. the semantic properties to display along with results)
    private static $PARAM_PRINTOUTS = 'po';
    // Parameters holding the query limit: max items to return (0 means default)
    private static $PARAM_LIMIT = 'limit';
    // Parameters holding the query offset: number of the first item to display
    private static $PARAM_OFFSET = 'offset';
    // Action name in the API
    private $ACTION_NAME;

    public function __construct($query, $moduleName) {
        parent :: __construct($query, $moduleName);
        global $wgSMWAskAPI_ActionName;
        $this->ACTION_NAME = $wgSMWAskAPI_ActionName;
    }

    public function execute() {
        global $wgUser;

        $params = $this->extractRequestParams();
        if (is_null($params[SMWAskAPI::$PARAM_QUERY]))
            $this->dieUsage('Must specify a semantic query (' . SMWAskAPI::$PARAM_QUERY . ')', 0);

        $query = $params[SMWAskAPI::$PARAM_QUERY];

        if (!is_null($params[SMWAskAPI::$PARAM_PRINTOUTS])) {
            $props = explode("|", $params[SMWAskAPI::$PARAM_PRINTOUTS]);
        } else {
            $props = array();
        }

        if( !isset($params[SMWAskAPI::$PARAM_LIMIT]) || is_null($limit = $params[SMWAskAPI::$PARAM_LIMIT]) || $limit == '' ){
            $limit = null;// null = 'infinity'
        }else if ( ($limit=intval($limit)) < 0 ){
            $this->dieUsage('Invalid ' . SMWAskAPI::$PARAM_LIMIT . '='.$limit.': if set, must be a non-negative integer. 0 value means default', 0);
        }

        if( !isset($params[SMWAskAPI::$PARAM_OFFSET]) || is_null($offset = $params[SMWAskAPI::$PARAM_OFFSET]) ){
            $offset = 0;// 0 is default value
        }else if ( ($offset=intval($offset)) < 0 ){
            $this->dieUsage('Invalid ' . SMWAskAPI::$PARAM_OFFSET . '='.$offset.': if set, must be a non-negative integer. Default value is 0', 0);
        }

        $res = $this->ask($query, $props, $limit, $offset);

        $result = array();

        $ask_errors = $res->getErrors();

        if (empty($ask_errors)) {
            $result['result'] = 'Success';
        } else {
            $result['result'] = 'Error';
            $this->getResult()->setIndexedTagName($ask_errors, 'list-item');
            $this->getResult()->addValue(array($this->ACTION_NAME), 'errors', $ask_errors);
        }

        $this->getResult()->addValue(array($this->ACTION_NAME, 'query'), SMWAskAPI::$PARAM_QUERY, $query);
        if (count($props) > 0) {
            $this->getResult()->setIndexedTagName($props, 'list-item');
            $this->getResult()->addValue(array($this->ACTION_NAME, 'query'), SMWAskAPI::$PARAM_PRINTOUTS, $props);
        }

        if( ! is_null($limit) ){
            $this->getResult()->addValue(array($this->ACTION_NAME, 'query'), SMWAskAPI::$PARAM_LIMIT, $limit);
        }
        if( $offset!=0 ){
            $this->getResult()->addValue(array($this->ACTION_NAME, 'query'), SMWAskAPI::$PARAM_OFFSET, $offset);
        }

        if ( $res->getCount() > 0 || $res->hasFurtherResults() )  {
            // We set the num of *displayed* results
            $this->getResult()->addValue(array($this->ACTION_NAME, 'results'), 'count', $res->getCount());

            // If more results can be found, say it
            if( $res->hasFurtherResults() ){
                $this->getResult()->addValue(array($this->ACTION_NAME, 'results'), 'hasMore', 'true');
            }

            $items = array();
            while (( $r = $res->getNext() ) !== false) {

                $items[] = $this->resultToItem($r);
            }

            $this->getResult()->setIndexedTagName($items, 'list-item');
            $this->getResult()->addValue(array($this->ACTION_NAME, 'results'), 'items', $items);
        }

        $this->getResult()->addValue(null, $this->ACTION_NAME, $result);
    }

    /**
     * Transform a results' row (ie. a result) into
     * an item, which is a simple associative array
     *
     * @param <type> $r
     * @return string
     */
    private function resultToItem($r) {

        // variables used to reconstruct URI from page title
        global $wgServer, $wgScriptPath;

        $rowsubject = false; // the wiki page value that this row is about
        $item = array(); // contains Property-Value pairs to characterize an Item
        $item['properties'] = array();
        foreach ($r as $field) {
            $pr = $field->getPrintRequest();
            if ($rowsubject === false) {
                $rowsubject = $field->getResultSubject();
                $item['title'] = $rowsubject->getShortText(null, null);
            }
            if ($pr->getMode() != SMWPrintRequest::PRINT_THIS) {
                $values = array();
                while (( $value = $field->getNextObject() ) !== false) {
                    switch ($value->getTypeID()) {
                        case '_geo':
                            $values[] = $value->getWikiValue();
                            break;
                        case '_num':
                            $values[] = $value->getValueKey();
                            break;
                        case '_dat':
                            $values[] = $value->getYear() . "-" . str_pad($value->getMonth(), 2, '0', STR_PAD_LEFT) . "-" . str_pad($value->getDay(), 2, '0', STR_PAD_LEFT) . " " . $value->getTimeString();
                            break;
                        default:
                            $values[] = $value->getShortText(null, null);
                    }
                }

                $this->addPropToItem($item, str_replace(" ", "_", strtolower($pr->getLabel())), $values);
            }
        }
        if ($rowsubject !== false) { // stuff in the page URI and some category data
            $item['uri'] = $wgServer . $wgScriptPath . '/index.php?title=' . $rowsubject->getPrefixedText();
            $page_cats = smwfGetStore()->getPropertyValues($rowsubject, SMWPropertyValue::makeProperty('_INST')); // TODO: set limit to 1 here
            if (count($page_cats) > 0) {
                $this->addPropToItem($item, 'type', array(reset($page_cats)->getShortHTMLText()));
            }
        }

        return $item;
    }

    private function addPropToItem(&$item, $propname, $propvalues) {

        switch (sizeof($propvalues)) {
            case 0: return;
            case 1:
                if ($propvalues[0] != '') {
                    $item['properties'][$propname] = $propvalues[0]; //todo leave it as an array?
                }
                break;
            default:
                $this->getResult()->setIndexedTagName($propvalues, 'list-item');
                $item['properties'][$propname] = $propvalues;
        }
    }

    /**
     * #ask itself.
     * Delegate the treatments to SMWQueryProcessor
     *
     * @var SMWQueryProcessor
     * @param <type> $m_querystring
     * @param <type> $props
     * @return <type>
     */
    private function ask($m_querystring, $props = array(), $limit=null, $offset=0) {

        $rawparams = array();

        if ($m_querystring != '') {
            $rawparams[] = $m_querystring;
        }

        foreach ($props as $prop) {
            $prop = trim($prop);
            if (( $prop != '' ) && ( $prop != '?' )) {
                if ($prop { 0 } != '?') {
                    $prop = '?' . $prop;
                }
                $rawparams[] = $prop;
            }
        }

        $m_params = array();
        $m_printouts = array();
        SMWQueryProcessor::processFunctionParams($rawparams, $m_querystring, $m_params, $m_printouts);

        $m_params['offset'] = $offset;
        if( ! is_null($limit) ){
            $m_params['limit'] = $limit;
        }

        $queryobj = SMWQueryProcessor::createQuery($m_querystring, $m_params, SMWQueryProcessor::SPECIAL_PAGE, null, $m_printouts);

        return smwfGetStore()->getQueryResult($queryobj);
    }

    public function mustBePosted() {
        return false;
    }

    public function isWriteMode() {
        return false;
    }

    protected function getAllowedParams() {
        return array(
            SMWAskAPI::$PARAM_QUERY => null,
            SMWAskAPI::$PARAM_PRINTOUTS => null,
            SMWAskAPI::$PARAM_LIMIT => null,
            SMWAskAPI::$PARAM_OFFSET => null
        );
    }

    protected function getParamDescription() {
        return array(
            SMWAskAPI::$PARAM_QUERY => 'Semantic query',
            SMWAskAPI::$PARAM_PRINTOUTS => 'Printouts : pipe-separate list of semantic properties to display with results (optional)',
            SMWAskAPI::$PARAM_LIMIT => 'Max number of items to return (optional - 0 is an accepted value ; leave empty to get all results)',
            SMWAskAPI::$PARAM_OFFSET => 'Number of items to skip when displaying results (optional - default is 0)'
        );
    }

    protected function getDescription() {
        return 'Execute a semantic query (#ask)';
    }

    protected function getExamples() {
        return array(
            'api.php?action=' . $this->ACTION_NAME . '&' . SMWAskAPI::$PARAM_QUERY . '=[[Special_need::fraises]]&' . SMWAskAPI::$PARAM_PRINTOUTS . '=Special_need|dummyproperty',
            'api.php?action=' . $this->ACTION_NAME . '&' . SMWAskAPI::$PARAM_QUERY . '=[[Special_need::fraises]]&' . SMWAskAPI::$PARAM_PRINTOUTS . '=Special_need|dummyproperty&' . SMWAskAPI::$PARAM_LIMIT . '=20&' . SMWAskAPI::$PARAM_OFFSET . '=2',
        );
    }

    public function getVersion() {
        return __CLASS__ . '$' . SMWASKAPI_VERSION; //TODO what is the norm here?
    }

}