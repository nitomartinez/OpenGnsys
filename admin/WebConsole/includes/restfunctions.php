<?php
 
/*
 * Function: multiRequest.
 * Params:   urls array, cURL options array.
 * Returns:  array with JSON requests.
 * Date:     2015-10-14
 */
function multiRequest($data, $options = array()) {
 
  // array of curl handles
  $curly = array();
  // data to be returned
  $result = array();
 
  // multi handle
  $mh = curl_multi_init();
 
  // loop through $data and create curl handles
  // then add them to the multi-handle
  foreach ($data as $id => $d) {
 

    $curly[$id] = curl_init();
 
    $url = (is_array($d) && !empty($d['url'])) ? $d['url'] : $d;
    curl_setopt($curly[$id], CURLOPT_URL, $url);
    curl_setopt($curly[$id], CURLOPT_HEADER, 0);
    curl_setopt($curly[$id], CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($curly[$id], CURLOPT_TIMEOUT, 1);
 
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
 
 
  // get content and remove handles
  foreach($curly as $id => $c) {
    $result[$id] = curl_multi_getcontent($c);
    curl_multi_remove_handle($mh, $c);
  }

 // all done
  curl_multi_close($mh);
 
  return $result;
}
 


/**
 * @brief Realiza una petición POST, PUT, GET, DELETE a una webservice. Pueden enviarse datos y cabeceras especificas
 * @param $method Metodo http (POST, GET, etc)
 * @param $url Url del webservice a consultar
 * @param $data array de datos a enviar. Ej. array("param" => "value") ==> index.php?param=value
 * @param $headers Cabeceras especificas de la peticion. Ej. array('Authorization: "9Ka7wG3EqhcjylUeQXITy0llj2TS8eKe"') 
 */
// Method: POST, PUT, GET etc
// Data: 
// Ej. callAPI("GET", "http://172.17.11.176/opengnsys/rest/index.php/repository/images?extensions[]=img&extensions[]=sum", array('Authorization: "9Ka7wG3EqhcjylUeQXITy0llj2TS8eKe"')) 
function callAPI($method, $url, $data = false, $headers = false)
{
    $curl = curl_init();

    switch ($method)
    {
        case "POST":
            curl_setopt($curl, CURLOPT_POST, 1);

            if ($data)
                curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
            break;
        case "PUT":
            curl_setopt($curl, CURLOPT_PUT, 1);
            break;
        default:
            if ($data)
                $url = sprintf("%s?%s", $url, http_build_query($data));
    }

    // Optional Authentication:
    //curl_setopt($curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    //curl_setopt($curl, CURLOPT_USERPWD, "username:password");

    curl_setopt($curl, CURLOPT_URL, $url);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
    if($headers != false){
	    curl_setopt($curl, CURLOPT_HTTPHEADER, $headers);
	}

    $result = curl_exec($curl);

    curl_close($curl);

    return $result;
}
?>