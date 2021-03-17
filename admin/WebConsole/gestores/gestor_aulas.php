<?php
// *************************************************************************************************************************************************
// Aplicación WEB: ogAdmWebCon
// Autor: José Manuel Alonso (E.T.S.I.I.) Universidad de Sevilla
// Fecha Creación: Año 2009-2010
// Fecha Última modificación: Agosto-2010
// Nombre del fichero: gestor_aulas.php
// Descripción :
//		Gestiona el mantenimiento de la tabla de aulas
// *************************************************************************************************************************************************
include_once("../includes/ctrlacc.php");
include_once("../clases/AdoPhp.php");
include_once("../clases/XmlPhp.php");
include_once("../clases/ArbolVistaXML.php");
include_once("../includes/CreaComando.php");
include_once("../includes/constantes.php");
include_once("./relaciones/aulas_eliminacion.php");
include_once("./relaciones/ordenadores_eliminacion.php");
include_once("../includes/opciones.php");
include_once("../includes/tftputils.php");
include_once("./relaciones/gruposordenadores_eliminacion.php");
//________________________________________________________________________________________________________
$opcion=0; // Inicializa parametros

$idaula=0; 
$nombreaula="";
$grupoid=0; 
$urlfoto="";
$inremotepc=false;
$cagnon=false;
$pizarra=false;
$ubicacion="";
$comentarios="";
$puestos=0;
$idordprofesor=0;
$horaresevini=0;
$horaresevfin=0;
$idmenu=0;
$idproautoexec=0;
######################## AGP
$idrepositorio=0;
$diskremotepc=0;
$partremotepc=0;
$imaremotepc=0;
$idimaremotepc=0;
$idperfilsoftimaremotepc=0;
######################## AGP
$oglive="ogLive";
$idperfilhard=0;
$modomul=0;
$ipmul="";
$pormul=0;
$velmul=0;
############## ADV
$router=0;
$netmask=0;
$modp2p=0;
$timep2p=0;
############ Ramón
$ntp="";
$dns="";
$proxy="";
############ UHU
$validacion="";
$paginalogin="";
$paginavalidacion="";
############ UHU
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
if (isset($_POST["opcion"])) $opcion=$_POST["opcion"]; // Recoge parametros

if (isset($_POST["grupoid"])) $grupoid=$_POST["grupoid"];
if (isset($_POST["idaula"])) $idaula=$_POST["idaula"];
if (isset($_POST["identificador"])) $idaula=$_POST["identificador"];

if (isset($_POST["nombreaula"])) $nombreaula=$_POST["nombreaula"]; 
if (isset($_POST["urlfoto"])) $urlfoto=$_POST["urlfoto"]; 
if (isset($_POST["inremotepc"])) $inremotepc=$_POST["inremotepc"]; 
if (isset($_POST["cagnon"])) $cagnon=$_POST["cagnon"]; 
if (isset($_POST["pizarra"])) $pizarra=$_POST["pizarra"];
if (isset($_POST["ubicacion"])) $ubicacion=$_POST["ubicacion"]; 
if (isset($_POST["comentarios"])) $comentarios=$_POST["comentarios"];
if (isset($_POST["puestos"])) $puestos=$_POST["puestos"]; 
if (isset($_POST["idordenador"])) $idordprofesor=$_POST["idordenador"];
if (isset($_POST["horaresevini"])) $horaresevini=$_POST["horaresevini"];
if (isset($_POST["horaresevfin"])) $horaresevini=$_POST["horaresevfin"];
if (isset($_POST["idmenu"])) $idmenu=$_POST["idmenu"]; 
if (isset($_POST["idprocedimiento"])) $idproautoexec=$_POST["idprocedimiento"]; 
if (isset($_POST["idrepositorio"])) $idrepositorio=$_POST["idrepositorio"]; 
if (isset($_POST["oglive"])) $oglive=$_POST["oglive"];
if (isset($_POST["idperfilhard"])) $idperfilhard=$_POST["idperfilhard"]; 
if (isset($_POST["modomul"])) $modomul=$_POST["modomul"]; 
if (isset($_POST["ipmul"])) $ipmul=$_POST["ipmul"]; 
if (isset($_POST["pormul"])) $pormul=$_POST["pormul"]; 
if (isset($_POST["velmul"])) $velmul=$_POST["velmul"]; 
############## ADV
if (isset($_POST["router"])) $router=$_POST["router"];
if (isset($_POST["netmask"])) $netmask=$_POST["netmask"]; 
if (isset($_POST["modp2p"])) $modp2p=$_POST["modp2p"]; 
if (isset($_POST["timep2p"])) $timep2p=$_POST["timep2p"]; 
################# Ramón
if (isset($_POST["ntp"])) $ntp=$_POST["ntp"]; 
if (isset($_POST["dns"])) $dns=$_POST["dns"]; 
if (isset($_POST["proxy"])) $proxy=$_POST["proxy"]; 
################# UHU
if (isset($_POST["validacion"])) $validacion=$_POST["validacion"];
if (isset($_POST["paginalogin"])) $paginalogin=$_POST["paginalogin"];
if (isset($_POST["paginavalidacion"])) $paginavalidacion=$_POST["paginavalidacion"];
################# UHU

$gidmenu=0;
$gidproautoexec=0;
$gidrepositorio=0;
$gidperfilhard=0;

if (isset($_POST["gidmenu"])) $gidmenu=$_POST["gidmenu"]; 
if (isset($_POST["gidprocedimiento"])) $gidproautoexec=$_POST["gidprocedimiento"]; 
if (isset($_POST["gidrepositorio"])) $gidrepositorio=$_POST["gidrepositorio"]; 
if (isset($_POST["gidperfilhard"])) $gidperfilhard=$_POST["gidperfilhard"]; 

$tablanodo=""; // Arbol para nodos insertados
$cmd=CreaComando($cadenaconexion); // Crea objeto comando
$resul=false;
if ($cmd){
	$resul=Gestiona();
	$cmd->Conexion->Cerrar();
}
//________________________________________________________________________________________________________
###	AGP	remotePC	######################################################################################
if (isset($_POST["diskremotepc"])) $diskremotepc=$_POST["diskremotepc"]; 
if (isset($_POST["partremotepc"])) $partremotepc=$_POST["partremotepc"]; 
if (isset($_POST["imaremotepc"])) $imaremotepc=$_POST["imaremotepc"]; 
$imaremoPC=explode("_",$imaremotepc);
$idimaremotepc=$imaremoPC[2];
$idperfilsoftimaremotepc=$imaremoPC[3];

###	AGP	remotePC	######################################################################################
///*
$cmd=CreaComando($cadenaconexion); // Crea objeto comando
$rs=new Recordset;
$cmd->texto="SELECT idordenador FROM ordenadores WHERE idaula=".$idaula;
$rs->Comando=&$cmd;
if (!$rs->Abrir()) return(true); // Error al abrir recordset
$rs->Primero();
while (!$rs->EOF){
			$idordremotepc=$rs->campos["idordenador"];
			RecorreOrdenadoresremotePC($cmd,$idordremotepc);
			$rs->Siguiente();
}
$rs->Cerrar();
//*/
//________________________________________________________________________________________________________
###	AGP	remotePC	######################################################################################
/*________________________________________________________________________________________________________
	Crea un arbol XML para el nuevo nodo insertado 
________________________________________________________________________________________________________*/
function SubarbolXML_aulas($idaula,$nombreaula){
	global 	$LITAMBITO_AULAS;
	$cadenaXML='<AULAS ';
	// Atributos		
	$cadenaXML.=' clickcontextualnodo="menu_contextual(this,' ."'flo_".$LITAMBITO_AULAS."'" .')"';
	$cadenaXML.=' imagenodo="../images/iconos/aula.gif"';
	$cadenaXML.=' infonodo="'.$nombreaula.'"';
	$cadenaXML.=' nodoid='.$LITAMBITO_AULAS.'-'.$idaula;
	$cadenaXML.='>';
	$cadenaXML.='</AULAS>';
	return($cadenaXML);
}
?> 
<HTML>
<HEAD>
	<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
<BODY>
	<SCRIPT language="javascript" src="../jscripts/propiedades_aulas.js"></SCRIPT>
<?php
	$literal="";
	switch($opcion){
		case $op_alta :
			$literal="resultado_insertar_aulas";
			break;
		case $op_modificacion:
			$literal="resultado_modificar_aulas";
			break;
		case $op_eliminacion :
			$literal="resultado_eliminar_aulas";
			break;
		default:
			break;
	}
echo '<p><span style="visibility:hidden" id="arbol_nodo">'.$tablanodo.'</span></p>';
if ($resul){
	echo '<SCRIPT language="javascript">'.chr(13);
	echo 'var oHTML'.chr(13);
	echo 'var cTBODY=document.getElementsByTagName("TBODY");'.chr(13);
	echo 'o=cTBODY.item(1);'.chr(13);
	if ($opcion==$op_alta )
		echo $literal."(1,'".$cmd->DescripUltimoError()." ',".$idaula.",o.innerHTML);".chr(13);
	else
		echo $literal."(1,'".$cmd->DescripUltimoError()." ','".$nombreaula."');".chr(13);
	echo '</SCRIPT>';
}
else{
	echo '<SCRIPT language="javascript">';
	echo $literal."(0,'".$cmd->DescripUltimoError()."',".$idaula.")";
	echo '</SCRIPT>';
}
?>
</BODY>
</HTML>	
<?php
/**************************************************************************************************************************************************
	Inserta, modifica o elimina datos en la tabla aulas
________________________________________________________________________________________________________*/
function Gestiona(){
	global	$cmd;
	global	$opcion;

	global	$idcentro;
	global	$grupoid;

	global	$idaula;
	global	$nombreaula;
	global	$urlfoto;
	global	$inremotepc;
	global	$cagnon;
	global	$pizarra;
	global	$ubicacion;
	global	$comentarios;
	global	$puestos;
	global	$idordprofesor;
	global  $horaresevini;
	global  $horaresevfin;

	global	$idmenu;
	global	$idproautoexec;
	global	$idrepositorio;
	global	$oglive;
	global	$idperfilhard;
	
	global $gidmenu;
	global $gidproautoexec;
	global $gidrepositorio;
	global $gidperfilhard;
	
	global	$modomul;
	global	$ipmul;
	global	$pormul;
	global	$velmul;
######################### ADV	
	global  $router;
	global	$netmask;
	global  $modp2p;
	global  $timep2p;
########################## Ramón
	global $ntp;
	global $dns;
	global $proxy;
	global $idioma;
########################## UHU
        global $validacion;
        global $paginalogin;
        global $paginavalidacion;
########################## UHU

	global	$op_alta;
	global	$op_modificacion;
	global	$op_eliminacion;
	global	$tablanodo;


	$cmd->CreaParametro("@grupoid",$grupoid,1);
	$cmd->CreaParametro("@idcentro",$idcentro,1);

	$cmd->CreaParametro("@idaula",$idaula,1);
	$cmd->CreaParametro("@nombreaula",$nombreaula,0);
	$cmd->CreaParametro("@urlfoto",$urlfoto,0);
	$cmd->CreaParametro("@inremotepc",$inremotepc,1);
	$cmd->CreaParametro("@cagnon",$cagnon,1);
	$cmd->CreaParametro("@pizarra",$pizarra,1);
	$cmd->CreaParametro("@ubicacion",$ubicacion,0);
	$cmd->CreaParametro("@comentarios",$comentarios,0);
	$cmd->CreaParametro("@puestos",$puestos,1);
	$cmd->CreaParametro("@idordprofesor",$idordprofesor,1);
	$cmd->CreaParametro("@horaresevini",$horaresevini,1);
	$cmd->CreaParametro("@horaresevfin",$horaresevfin,1);
	$cmd->CreaParametro("@idmenu",$idmenu,1);
	$cmd->CreaParametro("@idproautoexec",$idproautoexec,1);
	$cmd->CreaParametro("@idrepositorio",$idrepositorio,1);
	$cmd->CreaParametro("@oglivedir",$oglive,0);
	$cmd->CreaParametro("@idperfilhard",$idperfilhard,1);
	$cmd->CreaParametro("@ntp",$ntp,0);
	$cmd->CreaParametro("@dns",$dns,0);
	$cmd->CreaParametro("@proxy",$proxy,0);
	$cmd->CreaParametro("@modomul",$modomul,1);
	$cmd->CreaParametro("@ipmul",$ipmul,0);
	$cmd->CreaParametro("@pormul",$pormul,1);
	$cmd->CreaParametro("@velmul",$velmul,1);
############ ADV
	$cmd->CreaParametro("@netmask",$netmask,0);
	$cmd->CreaParametro("@router",$router,0);
	$cmd->CreaParametro("@modp2p",$modp2p,0);
	$cmd->CreaParametro("@timep2p",$timep2p,1);
############### ADV
############### UHU
        $cmd->CreaParametro("@validacion",$validacion,1);
        $cmd->CreaParametro("@paginalogin",$paginalogin,0);
        $cmd->CreaParametro("@paginavalidacion",$paginavalidacion,0);
############### UHU

	switch($opcion){
		case $op_alta :
			$cmd->texto = <<<EOD
INSERT INTO aulas
	(idcentro, grupoid, nombreaula, urlfoto, inremotepc, cagnon, pizarra,
	 ubicacion, comentarios, puestos, horaresevini, horaresevfin, router,
	 netmask, ntp, dns, proxy, modomul, ipmul, pormul, velmul, modp2p,
	 timep2p, validacion, paginalogin, paginavalidacion, oglivedir)
 VALUES (@idcentro, @grupoid, @nombreaula, @urlfoto, @inremotepc, @cagnon, @pizarra,
	 @ubicacion, @comentarios, @puestos, @horaresevini, @horaresevfin, @router,
	 @netmask, @ntp, @dns, @proxy, @modomul, @ipmul, @pormul, @velmul, @modp2p,
	 @timep2p, @validacion, @paginalogin, @paginavalidacion, @oglivedir);
EOD;
			$resul=$cmd->Ejecutar();
			if ($resul){ // Crea una tabla nodo para devolver a la página que llamó ésta
				$idaula=$cmd->Autonumerico();
				$arbolXML=SubarbolXML_aulas($idaula,$nombreaula);
				$baseurlimg="../images/signos"; // Url de las imagenes de signo
				$clasedefault="texto_arbol"; // Hoja de estilo (Clase por defecto) del árbol
				$arbol=new ArbolVistaXML($arbolXML,0,$baseurlimg,$clasedefault);
				$tablanodo=$arbol->CreaArbolVistaXML();
			}
			break;
		case $op_modificacion:
			$cmd->texto = <<<EOD
UPDATE aulas SET
	nombreaula=@nombreaula, urlfoto=@urlfoto, inremotepc=@inremotepc, cagnon=@cagnon,
	pizarra=@pizarra, ubicacion=@ubicacion, comentarios=@comentarios,
	puestos=@puestos, idordprofesor=@idordprofesor, router=@router, netmask=@netmask,
	ntp=@ntp, dns=@dns, proxy=@proxy, modomul=@modomul, ipmul=@ipmul, pormul=@pormul,
	velmul=@velmul, modp2p=@modp2p, timep2p=@timep2p, validacion=@validacion,
	paginalogin=@paginalogin, paginavalidacion=@paginavalidacion,
	oglivedir=IF(@oglivedir='0',oglivedir,@oglivedir)
  WHERE idaula=@idaula;
EOD;
			$resul=$cmd->Ejecutar();
			if ($resul){ // Crea una tabla nodo para devolver a la página que llamó ésta
				$clsUpdate="";	
				if($idmenu>0 || $gidmenu>0)	
					$clsUpdate.="idmenu=@idmenu,";
				if($idproautoexec>0 || $gidproautoexec>0)	
					$clsUpdate.="idproautoexec=@idproautoexec,";					
				if($idrepositorio>0 || $gidrepositorio>0)	
					$clsUpdate.="idrepositorio=@idrepositorio,";
				if($oglive != "0")	
					$clsUpdate .="oglivedir=@oglivedir,";
				if($idperfilhard>0 || $gidperfilhard>0)	
					$clsUpdate.="idperfilhard=@idperfilhard,";
				// UHU - Actualiza la validacion en los ordenadores
		                $clsUpdate .="validacion=@validacion,";
                                $clsUpdate .="paginalogin=@paginalogin,";
                                $clsUpdate .="paginavalidacion=@paginavalidacion,";

					
				if(!empty($clsUpdate)){				
					$clsUpdate=substr($clsUpdate,0,strlen($clsUpdate)-1); // Quita última coma
					$cmd->texto="UPDATE ordenadores SET ".$clsUpdate." WHERE idaula=@idaula";
					$resul=$cmd->Ejecutar();
				}	
				// Actualizar ficheros PXE de todos los ordenadores afectados.
				updateBootMode ($cmd, "idaula", $idaula, $idioma);
			}
			break;
		case $op_eliminacion :
			$resul=EliminaAulas($cmd,$idaula,"idaula");// Eliminación en cascada
			break;
		default:
			break;
	}
	return($resul);
}
/*________________________________________________________________________________________________________
	Crea un arbol XML para el nuevo nodo insertado 
________________________________________________________________________________________________________*/
function SubarbolXML_aulas($idaula,$nombreaula){
	global 	$LITAMBITO_AULAS;
	$cadenaXML='<AULAS ';
	// Atributos		
	$cadenaXML.=' clickcontextualnodo="menu_contextual(this,' ."'flo_".$LITAMBITO_AULAS."'" .')"';
	$cadenaXML.=' imagenodo="../images/iconos/aula.gif"';
	$cadenaXML.=' infonodo="'.$nombreaula.'"';
	$cadenaXML.=' nodoid='.$LITAMBITO_AULAS.'-'.$idaula;
	$cadenaXML.='>';
	$cadenaXML.='</AULAS>';
	return($cadenaXML);
}
###	AGP	remotePC	######################################################################################
///*
//________________________________________________________________________________________________________
function RecorreOrdenadoresRemotePC($cmd,$idordremotepc){
	global $cmd;
	global $idordremotepc;
	global $diskremotepc;
	global $partremotepc;
	global $idimaremotepc;
	global $idperfilsoftimaremotepc;

	$cmd->CreaParametro("@idordremotepc",$idordremotepc,1);
	$cmd->CreaParametro("@diskremotepc",$diskremotepc,1);
	$cmd->CreaParametro("@partremotepc",$partremotepc,1);
	$cmd->CreaParametro("@idimaremotepc",$idimaremotepc,1);
	$cmd->CreaParametro("@idperfilsoftimaremotepc",$idperfilsoftimaremotepc,1);
	
	$cmd->texto="SELECT numdisk,numpar FROM ordenadores_particiones
				 WHERE idordenador=@idordremotepc
				 AND numdisk=@diskremotepc 
				 AND numpar=@partremotepc";
	$rs=new Recordset;
	$rs->Comando=&$cmd; 
	if (!$rs->Abrir()) return; // Error al abrir recordset
	$NumdiskremoPC=$rs->campos["numdisk"];
	// Si los 3 campos tienen datos realizamos cambios
    if (  (!empty($diskremotepc)) && (!empty($partremotepc)) && (!empty($idimaremotepc))  ){
		// Si tienen algun disco realizamos operacion
		if ( !empty($NumdiskremoPC)){
			// Si tiene algun Disco Actualizamos
			$cmd->texto = "UPDATE ordenadores_particiones
						   SET idimagen=@idimaremotepc, idperfilsoft=@idperfilsoftimaremotepc
						   WHERE numdisk=@diskremotepc
						   AND numpar=@partremotepc
						   AND idordenador=@idordremotepc";
			$resul=$cmd->Ejecutar();
		}else{
			// Si NO tiene ningun Disco Insertamos
			$cmd->texto="INSERT INTO ordenadores_particiones (idordenador,numdisk,numpar,idimagen,idperfilsoft) 
						 VALUES ( @idordremotepc, @diskremotepc ,@partremotepc, @idimaremotepc, @idperfilsoftimaremotepc ) ";
			$resul=$cmd->Ejecutar();
		}
	}else{
			// NO realiza ningun cambio
			echo "";
	}
	$rs->Cerrar();
}
###	AGP	remotePC	######################################################################################
///*
?>