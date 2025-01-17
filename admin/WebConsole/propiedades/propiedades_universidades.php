<?php 
// *************************************************************************************************************************************************
// Aplicación WEB: ogAdmWebCon
// Autor: José Manuel Alonso (E.T.S.I.I.) Universidad de Sevilla
// Fecha Creación: Año 2009-2010
// Fecha Última modificación: Noviembre-2005
// Nombre del fichero: propiedades_universidades.php
// Descripción : 
//		 Presenta el formulario de captura de datos de una universidad  para insertar,modificar 
// *************************************************************************************************************************************************
include_once("../includes/ctrlacc.php");
include_once("../includes/opciones.php");
include_once("../includes/constantes.php");
include_once("../includes/CreaComando.php");
include_once("../includes/TomaDato.php");
include_once("../includes/HTMLSELECT.php");
include_once("../clases/AdoPhp.php");
include_once("../idiomas/php/".$idioma."/propiedades_universidades_".$idioma.".php");
//________________________________________________________________________________________________________
$opcion=0;
$opciones=array($TbMsg[0],$TbMsg[1],$TbMsg[2],$TbMsg[3]);
//________________________________________________________________________________________________________
$iduniversidad=0; 
$nombreuniversidad="";
$comentarios="";

if (isset($_GET["opcion"])) $opcion=$_GET["opcion"]; // Recoge parametros
if (isset($_GET["iduniversidad"])) $iduniversidad=$_GET["iduniversidad"]; 
if (isset($_GET["identificador"])) $iduniversidad=$_GET["identificador"]; 
//________________________________________________________________________________________________________
$cmd=CreaComando($cadenaconexion); // Crea objeto comando
if (!$cmd)
	Header('Location: '.$pagerror.'?herror=2'); // Error de conexión con servidor B.D.
if  ($opcion!=$op_alta){
	$resul=TomaPropiedades($cmd,$iduniversidad);
	if (!$resul)
		Header('Location: '.$pagerror.'?herror=3'); // Error de recuperación de datos.
}
else
	$urlicono="../images/universidad.jpg";
//________________________________________________________________________________________________________
?>
<HTML>
<HEAD>
	<TITLE>Administración web de universidades</TITLE>
	<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
	<LINK rel="stylesheet" type="text/css" href="../estilos.css">
	<SCRIPT language="javascript" src="../jscripts/propiedades_universidades.js"></SCRIPT>
	<SCRIPT language="javascript" src="../jscripts/opciones.js"></SCRIPT>
	<?php echo '<SCRIPT language="javascript" src="../idiomas/javascripts/'.$idioma.'/propiedades_universidades_'.$idioma.'.js"></SCRIPT>'?>
</HEAD>
<BODY>
<DIV  align=center>
<FORM  name="fdatos" action="../gestores/gestor_universidades.php" method="post"> 
	<INPUT type=hidden name=opcion value=<?php echo $opcion?>>
	<INPUT type=hidden name=iduniversidad value=<?php echo $iduniversidad?>>
	<P align=center class=cabeceras><?php echo $TbMsg[4]?><BR>
	<SPAN class=subcabeceras><?php echo $opciones[$opcion]?></SPAN></P>
	<TABLE  align=center border=0 cellPadding=1 cellSpacing=1 class=tabla_datos>
<!------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------->
		<TR>
			<TH align=center&nbsp;><?php echo $TbMsg[5]?>&nbsp;</TH>
			<?php echo '<TD colspan=3><INPUT  class="formulariodatos" name=nombreuniversidad style="width:350" type=text value="'.$nombreuniversidad.'"></TD>';?>
		</TR>
	<!------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------->
		<TR>
			<TH align=center>&nbsp;<?php echo $TbMsg[6]?>&nbsp;</TH>
			<?php if ($opcion==$op_eliminacion)
					echo '<TD>'.$comentarios.'</TD>';
				else
					echo '<TD><TEXTAREA   class="formulariodatos" name=comentarios rows=3 cols=66>'.$comentarios.'</TEXTAREA></TD>';
			?>
		</TR>	
<!------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------->
	</TABLE>
</FORM>
</DIV>
<?php
//________________________________________________________________________________________________________
include_once("../includes/opcionesbotonesop.php");
//________________________________________________________________________________________________________
?>
</BODY>
</HTML>
<?php
//________________________________________________________________________________________________________
//	Recupera los datos de un universidad
//		Parametros: 
//		- cmd: Una comando ya operativo (con conexión abierta)  
//		- id: El identificador de la universidad
//________________________________________________________________________________________________________
function TomaPropiedades($cmd,$id){
	global $iduniversidad;
	global $nombreuniversidad;
	global $comentarios;
	$id=1;
	$rs=new Recordset; 
	$cmd->texto="SELECT * FROM universidades WHERE iduniversidad=".$id;
	$rs->Comando=&$cmd; 
	if (!$rs->Abrir()) return(false); // Error al abrir recordset
	$rs->Primero(); 
	if (!$rs->EOF){
		$nombreuniversidad=$rs->campos["nombreuniversidad"];
		$comentarios=$rs->campos["comentarios"];
	}
	$rs->Cerrar();
	return(true);
}
