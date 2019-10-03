
<?php

define('OG_REST_URL', 'http://127.0.0.1:8888/');

define('GET', 1);
define('POST', 2);
define('CUSTOM', 3);

define('OG_REST_CMD_CLIENTS', 'clients');
define('OG_REST_CMD_WOL', 'wol');
define('OG_REST_CMD_SESSION', 'session');
define('OG_REST_CMD_RUN', 'shell/run');
define('OG_REST_CMD_OUTPUT', 'shell/output');
define('OG_REST_CMD_POWEROFF', 'poweroff');
define('OG_REST_CMD_REBOOT', 'reboot');
define('OG_REST_CMD_STOP', 'stop');
define('OG_REST_CMD_REFRESH', 'refresh');
define('OG_REST_CMD_HARDWARE', 'hardware');
define('OG_REST_CMD_SOFTWARE', 'software');
define('OG_REST_CMD_CREATE_IMAGE', 'image/create');
define('OG_REST_CMD_RESTORE_IMAGE', 'image/restore');

define('OG_REST_PARAM_CLIENTS', 'clients');
define('OG_REST_PARAM_ADDR', 'addr');
define('OG_REST_PARAM_MAC', 'mac');
define('OG_REST_PARAM_DISK', 'disk');
define('OG_REST_PARAM_PART', 'partition');
define('OG_REST_PARAM_RUN', 'run');
define('OG_REST_PARAM_TYPE', 'type');
define('OG_REST_PARAM_STATE', 'state');
define('OG_REST_PARAM_NAME', 'name');
define('OG_REST_PARAM_REPOS', 'repository');
define('OG_REST_PARAM_ID', 'id');
define('OG_REST_PARAM_CODE', 'code');
define('OG_REST_PARAM_PROFILE', 'profile');
define('OG_REST_PARAM_TYPE', 'type');

$conf_file = parse_ini_file(__DIR__ . '/../../etc/ogAdmRepo.cfg');
define('OG_REST_API_TOKEN', 'Authorization: ' . $conf_file['ApiToken']);

function common_request($command, $type, $data = null) {

	$json = json_encode($data);

	$service_url = OG_REST_URL.$command;

	$curl = curl_init($service_url);
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($curl, CURLOPT_HTTPHEADER, array(
		OG_REST_API_TOKEN,
	));

	switch ($type) {
		default:
		case GET:
			break;
		case POST:
			curl_setopt($curl, CURLOPT_POST, true);
			curl_setopt($curl, CURLOPT_POSTFIELDS, $json);
	}

	$curl_response = curl_exec($curl);
	$info = curl_getinfo($curl);

	if ($curl_response === false || $info['http_code'] != 200) {
		syslog(LOG_ERR, 'error occured during curl exec. Additioanl info: ' . print_r($info, TRUE));
		return 0;
	}

	curl_close($curl);

	syslog(LOG_INFO, 'response '.$command.' ok!');

	return json_decode($curl_response, true);
}


function shell($case, $string_ips, $command) {

	$ips = explode(';',$string_ips);

	switch ($case) {
		case 1:
			$data = array(OG_REST_PARAM_CLIENTS => $ips,
				OG_REST_PARAM_RUN => $command);
			$command = OG_REST_CMD_RUN;
			break;
		default:
		case 2:
			$data = array(OG_REST_PARAM_CLIENTS => $ips);
			$command = OG_REST_CMD_OUTPUT;
	}

	$result = common_request($command, POST,
		$data)[OG_REST_PARAM_CLIENTS][0]['output'];

	return (is_null($result) ? '1' : $result);
}

function clients($case, $ips) {

	switch ($case) {
		case 1:
			$type = POST;
			$data = array(OG_REST_PARAM_CLIENTS => $ips);
			break;
		case 2:
			$type = GET;
			$data = null;
			break;
	}

	$result = common_request(OG_REST_CMD_CLIENTS, $type, $data);

	$trama_notificacion = "";
	if (isset($result[OG_REST_PARAM_CLIENTS])) {
		foreach ($result[OG_REST_PARAM_CLIENTS] as $client) {
			$trama_notificacion .= $client[OG_REST_PARAM_ADDR].'/'.
				$client[OG_REST_PARAM_STATE].';';
		}
	}

	return $trama_notificacion;
}

function wol($type_wol, $macs, $ips) {

	switch ($type_wol) {
		default:
		case 1:
			$wol = 'broadcast';
			break;
		case 2:
			$wol = 'unicast';
	}

	$clients = array();

	for($i=0; $i<count($macs); $i++) {
		$clients[] = array(OG_REST_PARAM_ADDR => $ips[$i],
			OG_REST_PARAM_MAC => $macs[$i]);
	}

	$data = array(OG_REST_PARAM_TYPE => $wol,
		OG_REST_PARAM_CLIENTS => $clients);

	common_request(OG_REST_CMD_WOL, POST, $data);
}

function session($string_ips, $params) {

	preg_match_all('!\d{1}!', $params, $matches);

	$ips = explode(';',$string_ips);
	$disk = $matches[0][0];
	$part = $matches[0][1];

	$data = array(OG_REST_PARAM_CLIENTS => $ips,
		OG_REST_PARAM_DISK => $disk, OG_REST_PARAM_PART => $part);

	common_request(OG_REST_CMD_SESSION, POST, $data);
}

function create_image($string_ips, $params) {

	preg_match_all('/(?<=\=)(.*?)(?=\r)/', $params, $matches);

	$ips = explode(';',$string_ips);
	$disk = $matches[0][0];
	$part = $matches[0][1];
	$code = $matches[0][2];
	$id = $matches[0][3];
	$name = $matches[0][4];
	$repos = $matches[0][5];

	$data = array(OG_REST_PARAM_CLIENTS => $ips,
		OG_REST_PARAM_DISK => $disk,
		OG_REST_PARAM_PART => $part,
		OG_REST_PARAM_CODE => $code,
		OG_REST_PARAM_ID => $id,
		OG_REST_PARAM_NAME => $name,
		OG_REST_PARAM_REPOS => $repos);

	common_request(OG_REST_CMD_CREATE_IMAGE, POST, $data);
}

function restore_image($string_ips, $params) {

	preg_match_all('/(?<=\=)(.*?)(?=\r)/', $params, $matches);

	$ips = explode(';',$string_ips);
	$disk = $matches[0][0];
	$part = $matches[0][1];
	$image_id = $matches[0][2];
	$name = $matches[0][3];
	$repos = $matches[0][4];
	$profile = $matches[0][5];
	$type = $matches[0][6];

	$data = array(OG_REST_PARAM_DISK => $disk, OG_REST_PARAM_PART => $part,
		OG_REST_PARAM_ID => $image_id, OG_REST_PARAM_NAME => $name,
		OG_REST_PARAM_REPOS => $repos,
		OG_REST_PARAM_PROFILE => $profile,
		OG_REST_PARAM_TYPE => $type,
		OG_REST_PARAM_CLIENTS => $ips);

	common_request(OG_REST_CMD_RESTORE_IMAGE, POST, $data);
}

function poweroff($string_ips) {

	$ips = explode(';',$string_ips);

	$data = array(OG_REST_PARAM_CLIENTS => $ips);

	common_request(OG_REST_CMD_POWEROFF, POST, $data);
}

function reboot($string_ips) {

	$ips = explode(';',$string_ips);

	$data = array(OG_REST_PARAM_CLIENTS => $ips);

	common_request(OG_REST_CMD_REBOOT, POST, $data);
}

function stop($string_ips) {

	$ips = explode(';',$string_ips);

	$data = array(OG_REST_PARAM_CLIENTS => $ips);

	common_request(OG_REST_CMD_STOP, POST, $data);
}

function refresh($string_ips) {

	$ips = explode(';',$string_ips);

	$data = array(OG_REST_PARAM_CLIENTS => $ips);

	common_request(OG_REST_CMD_REFRESH, POST, $data);
}

function hardware($string_ips) {

	$ips = explode(';',$string_ips);

	$data = array(OG_REST_PARAM_CLIENTS => $ips);

	common_request(OG_REST_CMD_HARDWARE, POST, $data);
}

function software($string_ips) {

	$ips = explode(';',$string_ips);

	$data = array(OG_REST_PARAM_CLIENTS => $ips);

	common_request(OG_REST_CMD_SOFTWARE, POST, $data);
}

/*
 * @function multiRequest.
 * @param    URLs array (may include header and POST data), cURL options array.
 * @return   Array of arrays with JSON requests and response codes.
 * @warning  Default options: does not verifying certificate, connection timeout 200 ms.
 * @Date     2015-10-14
 */
function multiRequest($data, $options=array(CURLOPT_SSL_VERIFYHOST => false, CURLOPT_SSL_VERIFYPEER => false, CURLOPT_TIMEOUT_MS => 500)) {
 
  // array of curl handles
  $curly = array();
  // Data to be returned (response data and code)
  $result = array();
 
  // multi handle
  $mh = curl_multi_init();
 
  // loop through $data and create curl handles
  // then add them to the multi-handle
  foreach ($data as $id => $d) {
 

    $curly[$id] = curl_init();
 
    $url = (is_array($d) && !empty($d['url'])) ? $d['url'] : $d;
    curl_setopt($curly[$id], CURLOPT_URL, $url);
    // HTTP headers?
    if (is_array($d) && !empty($d['header'])) {
       curl_setopt($curly[$id], CURLOPT_HTTPHEADER, $d['header']);
    } else {
       curl_setopt($curly[$id], CURLOPT_HEADER, 0);
    }
    curl_setopt($curly[$id], CURLOPT_RETURNTRANSFER, 1);
 
    // post?
    if (is_array($d)) {
      if (!empty($d['post'])) {
        curl_setopt($curly[$id], CURLOPT_POST, 1);
        curl_setopt($curly[$id], CURLOPT_POSTFIELDS, $d['post']);
      }
    }

    // extra options?
    if (!empty($options)) {
      curl_setopt_array($curly[$id], $options);
    }
 
    curl_multi_add_handle($mh, $curly[$id]);
  }
 
  // execute the handles
  $running = null;
  do {
    curl_multi_exec($mh, $running);
  } while($running > 0);
 
 
  // Get content and HTTP code, and remove handles
  foreach($curly as $id => $c) {
    $result[$id]['data'] = curl_multi_getcontent($c);
    $result[$id]['code'] = curl_getinfo($c, CURLINFO_HTTP_CODE);
    curl_multi_remove_handle($mh, $c);
  }

 // all done
  curl_multi_close($mh);
 
  return $result;
}

