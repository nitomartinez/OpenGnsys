<?php
// *************************************************************************************************************************************************
// Aplicación WEB: ogAdmWebCon
// Autor: José Manuel Alonso (E.T.S.I.I.) Universidad de Sevilla
// Fecha Creación: Año 2009-2010
// Fecha Última modificación: Agosto-2010
// Nombre del fichero: gestor_ordenadores.php
// Descripción :
//		Gestiona el mantenimiento de la tabla de ordenadores
// Versión 1.1.0: Al insertar ordenador se comprueba que no existen duplicados nombre, ip y mac
// Autor: Irina Gómez  - ETSII, Universidad de Sevilla
// Fecha: 2016-03-04
// *************************************************************************************************************************************************
include_once("../includes/ctrlacc.php");
include_once("../clases/AdoPhp.php");
include_once("../clases/XmlPhp.php");
include_once("../clases/ArbolVistaXML.php");
include_once("../includes/CreaComando.php");
include_once("../includes/constantes.php");
include_once("./relaciones/ordenadores_eliminacion.php");
include_once("../includes/tftputils.php");
include_once("../includes/opciones.php");
include_once("../idiomas/php/".$idioma."/gestor_ordenadores_".$idioma.".php");

//________________________________________________________________________________________________________
$opcion=0; // Inicializa parametros

$fotoordenador="";
$grupoid=0; 
$idaula=0; 
$idordenador=0; 
$nombreordenador="";
$numserie="";
$ip="";
$mac="";
$idperfilhard=0;
$idrepositorio=0;
### AGP
$oglive="ogLive";
$idmenu=0;
$idprocedimiento=0;
$idimagen=0;
$colocar="";
#### ADV
$netiface="";
$netdriver="";
### UHU
$validacion="";
$paginalogin="";
$paginavalidacion="";
### Ramón
$arranque="";
### Irina
$datosduplicados="";

//##agp
if (isset($_FILES['archivo'])) {
	if($_FILES['archivo']['type']=="image/gif" || $_FILES['archivo']['type']=="image/jpeg" || $_FILES['archivo']['type']=="image/jpg" || $_FILES['archivo']['type']=="image/png" || $_FILES['archivo']['type']=="image/JPG") {
		$uploaddir ="../images/fotos/";
		$uploadfile = $uploaddir.$_FILES['archivo']['name'];
		move_uploaded_file($_FILES['archivo']['tmp_name'], $uploadfile); 
		#copy($_FILES['archivo']['tmp_name'], $uploadfile);
	}
}
//##agp
if (isset($_POST["fotoordenador"])) $fotoordenador=$_POST["fotoordenador"];
if (isset($_POST["opcion"])) $opcion=$_POST["opcion"]; // Recoge parametros
if (isset($_POST["grupoid"])) $grupoid=$_POST["grupoid"];
if (isset($_POST["idaula"])) $idaula=$_POST["idaula"];
if (isset($_POST["idordenador"])) $idordenador=$_POST["idordenador"];
if (isset($_POST["identificador"])) $idordenador=$_POST["identificador"];
if (isset($_POST["nombreordenador"])) $nombreordenador=$_POST["nombreordenador"];
if (isset($_POST["numserie"])) $numserie=$_POST["numserie"];
$maintenance=$_POST["maintenance"]??0;
if (isset($_POST["ip"])) $ip=$_POST["ip"];
if (isset($_POST["mac"])) $mac=str_replace(":","",$_POST["mac"]);
if (isset($_POST["idperfilhard"])) $idperfilhard=$_POST["idperfilhard"];
if (isset($_POST["idrepositorio"])) $idrepositorio=$_POST["idrepositorio"];
if (isset($_POST["seleoglive"])) $oglive=$_POST["seleoglive"];
if (isset($_POST["idmenu"])) $idmenu=$_POST["idmenu"];
if (isset($_POST["idprocedimiento"])) $idprocedimiento=$_POST["idprocedimiento"];

if (isset($_POST["netiface"])) $netiface=$_POST["netiface"];
if (isset($_POST["netdriver"])) $netdriver=$_POST["netdriver"];
######## UHU
if (isset($_POST["validacion"])) $validacion=$_POST["validacion"];
if (isset($_POST["paginalogin"])) $paginalogin=$_POST["paginalogin"];
if (isset($_POST["paginavalidacion"])) $paginavalidacion=$_POST["paginavalidacion"];
######## Ramón
if (isset($_POST["arranque"])) $arranque=$_POST["arranque"];
######## AGP
if (isset($_POST["coloc"])) $colocar=$_POST["coloc"];
	if ($colocar=="s"){
		
		$cmd=CreaComando($cadenaconexion); // Crea objeto comando
		$rs=new Recordset; 
		$cmd->texto="SELECT * FROM ordenadores WHERE idordenador=".$idordenador;
		$rs->Comando=&$cmd; 
		if (!$rs->Abrir()) return(false); // Error al abrir recordset
		$rs->Primero(); 
		if (!$rs->EOF){
			$arranque=$rs->campos["arranque"];
		$rs->Cerrar();
		}
	}
######## AGP
		
$tablanodo=""; // Arbol para nodos insertados
//________________________________________________________________________________________________________
$cmd=CreaComando($cadenaconexion); // Crea objeto comando
$resul=false;
if ($cmd){
	if ($idaula==0) 
		$idaula=toma_aula($cmd,$grupoid);
	$resul=Gestiona();
	$cmd->Conexion->Cerrar();
}
if($opcion!=$op_movida){
	echo '<HTML>';
	echo '<HEAD>';
	echo '	<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">';
	echo '<BODY>';
	echo '<P><SPAN style="visibility:hidden" id="arbol_nodo">'.$tablanodo.'</SPAN></P>';
	echo '	<SCRIPT language="javascript" src="../jscripts/propiedades_ordenadores.js"></SCRIPT>';
	echo '<SCRIPT language="javascript">'.chr(13);
	if ($resul){
		echo 'var oHTML'.chr(13);
		echo 'var cTBODY=document.getElementsByTagName("TBODY");'.chr(13);
		echo 'o=cTBODY.item(1);'.chr(13);
	}
}
//________________________________________________________________________________________________________
	$literal="";
	switch($opcion){
		case $op_alta :
			$literal="resultado_insertar_ordenadores";
			break;
		case $op_modificacion:
			$literal="resultado_modificar_ordenadores";
			break;
		case $op_eliminacion :
			$literal="resultado_eliminar_ordenadores";
			break;
		case $op_movida :
			$literal="resultado_cambiar_ordenadores";
			break;
		default:
			break;
	}
if ($resul){
	if ($opcion == $op_alta) {
	    if ( $datosduplicados != '') {
		echo $literal."(0,'".$TbMsg["DUPLICADO"].$datosduplicados." ',".$idordenador.",o.innerHTML);".chr(13);
	    } else {
		echo $literal."(1,'".$cmd->DescripUltimoError()." ',".$idordenador.",o.innerHTML);".chr(13);
	    }
    } elseif ($opcion == $op_modificacion) {
	    if ( $datosduplicados != '') {
		echo $literal."(0,'".$TbMsg["DUPLICADO"].$datosduplicados." ','".$nombreordenador."');".chr(13);
	    } else {
		echo $literal."(1,'".$cmd->DescripUltimoError()." ','".$nombreordenador."');".chr(13);
	    }
    }
	else
		echo $literal."(1,'".$cmd->DescripUltimoError()." ','".$nombreordenador."');".chr(13);
}
else
	echo $literal."(0,'".$cmd->DescripUltimoError()."',".$idordenador.")";

if($opcion!=$op_movida){
	echo '	</SCRIPT>';
	echo '</BODY>	';
	echo '</HTML>';	
}
?>
<script>
	// Capturar el iframe donde se muestra el arbol de aulas,
	// Al estar dentro del iframe de contenido, debemos acceder al padre y desde ahi acceder al iframe del arbol para recargarlo
	var iframe = this.parent.document.getElementsByName("frame_arbol")[0];
	// recargar iframe
	iframe.src = iframe.src;
</script>
<?php
/**************************************************************************************************************************************************
	Busca identificador del aula de un grupo de ordenador .Devuelve el identificador del aula a la que pertenece el grupo 
		Parametros: 
		- cmd:Una comando ya operativo (con conexión abierta)  
________________________________________________________________________________________________________*/
function toma_aula($cmd,$idgrupo){
	$rs=new Recordset; 
	$cmd->texto="SELECT idaula FROM gruposordenadores WHERE idgrupo=".$idgrupo;
	$rs->Comando=&$cmd; 
	if (!$rs->Abrir()) return(0); // Error al abrir recordset
	$rs->Primero(); 
	if (!$rs->EOF)
		return($rs->campos["idaula"]);
	else
		return(0);
}
/*________________________________________________________________________________________________________
	Inserta, modifica o elimina datos en la tabla ordenadores
________________________________________________________________________________________________________*/
function Gestiona(){
	global $cmd;
	global $opcion;
	global $fotoordenador;
	global $grupoid;
	global $idordenador;
	global $nombreordenador;
	global $numserie;
	global $maintenance;
	global $ip;
	global $mac;
	global $idaula;
	global $idperfilhard;
	global $idrepositorio;
	global $oglive;
	global $idmenu;
	global $idprocedimiento;
	global $netiface;
	global $netdriver;
######################## UHU
        global $validacion;
	global $paginalogin;
        global $paginavalidacion;
######################## Ramón
        global $arranque;
        global $idioma;

	global $op_alta;
	global $op_modificacion;
	global $op_eliminacion;
	global $op_movida;
	global $tablanodo;

####################### Irina
	global $datosduplicados;

	
	$cmd->CreaParametro("@grupoid",$grupoid,1);
	$cmd->CreaParametro("@idaula",$idaula,1);
	$cmd->CreaParametro("@idordenador",$idordenador,1);
	$cmd->CreaParametro("@nombreordenador",$nombreordenador,0);
	$cmd->CreaParametro("@numserie",$numserie,0);
	$cmd->CreaParametro("@maintenance",$maintenance,1);
	$cmd->CreaParametro("@ip",$ip,0);
	$cmd->CreaParametro("@mac",$mac,0);
	$cmd->CreaParametro("@idperfilhard",$idperfilhard,1);
	$cmd->CreaParametro("@idrepositorio",$idrepositorio,1);
	$cmd->CreaParametro("@oglivedir",$oglive,0);
	$cmd->CreaParametro("@idmenu",$idmenu,1);
	$cmd->CreaParametro("@idprocedimiento",$idprocedimiento,1);
	$cmd->CreaParametro("@netiface",$netiface,0);
	$cmd->CreaParametro("@netdriver",$netdriver,0);
	$cmd->CreaParametro("@fotoordenador",$fotoordenador,0);
######################################################### UHU
        $cmd->CreaParametro("@validacion",$validacion,0);
    	$cmd->CreaParametro("@paginalogin",$paginalogin,0);
	$cmd->CreaParametro("@paginavalidacion",$paginavalidacion,0);
######################################################### UHU


	switch($opcion){
		case $op_alta :
            $duplicates = checkDuplicates($cmd, $datosduplicados, $idordenador, $nombreordenador, $ip, $mac);
            // Si no hay datos duplicados insertamos el ordenador;
            if (!$duplicates) {
		    $cmd->texto = <<<EOD
INSERT INTO ordenadores
	(nombreordenador, numserie, maintenance, ip, mac,
	idperfilhard, idrepositorio, oglivedir, idmenu, idproautoexec,
	idaula, grupoid, netiface, netdriver, fotoord,
	validacion, paginalogin, paginavalidacion)
VALUES (@nombreordenador, @numserie, @maintenance, @ip, @mac,
	@idperfilhard, @idrepositorio, @oglivedir, @idmenu, @idprocedimiento,
	@idaula, @grupoid, @netiface, @netdriver, @fotoordenador,
	@validacion, @paginalogin, @paginavalidacion);
EOD;
             }
            $resul=$cmd->Ejecutar();
			if ($resul){ // Crea una tabla nodo para devolver a la página que llamó ésta
			    $idordenador=$cmd->Autonumerico();
			    // Crear fichero TFTP/PXE por defecto para el nuevo ordenador.
			    createBootMode ($cmd, "", $nombreordenador, $idioma); 
			    // Insertar datos en el árbol de configuración.
			    $arbolXML=SubarbolXML_ordenadores($idordenador,$nombreordenador);
			    $baseurlimg="../images/signos"; // Url de las imagenes de signo
			    $clasedefault="texto_arbol"; // Hoja de estilo (Clase por defecto) del árbol
			    $arbol=new ArbolVistaXML($arbolXML,0,$baseurlimg,$clasedefault);
			    $tablanodo=$arbol->CreaArbolVistaXML();
			}
			break;
        case $op_modificacion:
            $duplicates = checkDuplicates($cmd, $datosduplicados, $idordenador, $nombreordenador, $ip, $mac);
            if (!$duplicates) {
		    $cmd->texto = <<<EOD
UPDATE ordenadores
   SET nombreordenador=@nombreordenador, numserie=@numserie, maintenance=@maintenance,
       ip=@ip, mac=@mac, idperfilhard=@idperfilhard,
       idrepositorio=@idrepositorio, oglivedir=@oglivedir, idmenu=@idmenu,
       idproautoexec=@idprocedimiento, netiface=@netiface, netdriver=@netdriver,
       fotoord=@fotoordenador,
       validacion=@validacion, paginalogin=@paginalogin,paginavalidacion=@paginavalidacion
   WHERE idordenador=@idordenador;
EOD;
            }
			$resul=$cmd->Ejecutar();
			// Actualizar fichero TFTP/PXE a partir de la plantilla asociada.
			createBootMode ($cmd, $arranque, $nombreordenador, $idioma);
			break;
		case $op_eliminacion :
			$resul=EliminaOrdenadores($cmd,$idordenador,"idordenador");// Eliminación en cascada
			// Borrar fichero PXE.
			deleteBootFile ($mac);
			break;
		case $op_movida :
			$cmd->texto="UPDATE ordenadores SET idaula=@idaula, grupoid=@grupoid WHERE idordenador=@idordenador";
			$resul=$cmd->Ejecutar();
			// Actualizar fichero TFTP/PXE a partir de la plantilla asociada.
			createBootMode ($cmd, $arranque, $nombreordenador, $idioma);
			break;
		default:
			break;
	}
	return($resul);
}

function checkDuplicates(&$cmd, &$duplicate_data, $computer_id, $computer_name, $ip, $mac){
	$cmd->texto="SELECT idordenador,nombreordenador,ip,mac FROM  ordenadores
		WHERE nombreordenador=@nombreordenador OR ip=@ip OR mac=@mac";
	$rs = new Recordset;
	$rs->Comando=&$cmd;
	if (!$rs->Abrir()) return(0);
	$rs->Primero();
	while (!$rs->EOF) {
		if ($computer_id != $rs->campos["idordenador"]) {
			if ( $computer_name == $rs->campos["nombreordenador"])
				$duplicate_data ="nombre: $computer_name,";
			if ( $ip == $rs->campos["ip"])
				$duplicate_data .=" ip: $ip,";
			if (strtoupper($mac) == strtoupper($rs->campos["mac"]))
				$duplicate_data .=" mac: $mac,";
	   }
	   $rs->Siguiente();
	}
	$rs->Cerrar();
	$duplicate_data = trim($duplicate_data, ',');
	$ret = !empty($duplicate_data);
	return($ret);
}

/*________________________________________________________________________________________________________
	Crea un arbol XML para el nuevo nodo insertado 
________________________________________________________________________________________________________*/
function SubarbolXML_ordenadores($idordenador,$nombreordenador){
		global $LITAMBITO_ORDENADORES;
		$cadenaXML='<ORDENADOR';
		// Atributos			
		$cadenaXML.=' clickcontextualnodo="menu_contextual(this,' ."'flo_".$LITAMBITO_ORDENADORES."'" .')"';
		$cadenaXML.=' imagenodo="../images/iconos/ordenador.gif"';
		$cadenaXML.=' infonodo="'.$nombreordenador.'"';
		$cadenaXML.=' nodoid='.$LITAMBITO_ORDENADORES.'-'.$idordenador;
		$cadenaXML.='></ORDENADOR>';
		return($cadenaXML);
} 
?>

