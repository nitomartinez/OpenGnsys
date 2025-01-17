<?php 
// *************************************************************************************************************************************************
// Aplicación WEB: ogAdmWebCon
// Autor: José Manuel Alonso (E.T.S.I.I.) Universidad de Sevilla
// Fecha Creación: Año 2009-2010
// Fecha Última modificación: Agosto-2010
// Nombre del fichero: propiedades_centros.php
// Descripción : 
//		 Presenta el formulario de captura de datos de un centro para insertar,modificar y eliminar
/**
 * @file    propiedades_centros.php   
 * @version 1.1.0 - Se incluye la unidad organizativa como parametro del kernel: ogunit=directorio_unidad (ticket #678)
 * @author  Irina Gómez - ETSII Universidad de Sevilla
 * @date     2015-12-16
 */
// *************************************************************************************************************************************************
include_once("../includes/ctrlacc.php");
include_once("../includes/opciones.php");
include_once("../includes/CreaComando.php");
include_once("../includes/TomaDato.php");
include_once("../includes/HTMLSELECT.php");
include_once("../clases/AdoPhp.php");
include_once("../idiomas/php/".$idioma."/propiedades_centros_".$idioma.".php");
//________________________________________________________________________________________________________
$opcion=0;
$opciones=array($TbMsg[0],$TbMsg[1],$TbMsg[2],$TbMsg[3]);
//________________________________________________________________________________________________________
$idcentro=0; 
$nombrecentro="";
$identidad=0;
$grupoid=0;
$comentarios="";
$directorio="";

if (isset($_GET["opcion"])) $opcion=$_GET["opcion"]; // Recoge parametros 
if (isset($_GET["idcentro"])) $idcentro=$_GET["idcentro"]; 
if (isset($_GET["identidad"])) $identidad=$_GET["identidad"]; 
if (isset($_GET["identificador"])) $idcentro=$_GET["identificador"]; 

//________________________________________________________________________________________________________
$cmd=CreaComando($cadenaconexion); // Crea objeto comando
if (!$cmd)
	Header('Location: '.$pagerror.'?herror=2'); // Error de conexión con servidor B.D.
if  ($opcion!=$op_alta){
	$resul=TomaPropiedades($cmd,$idcentro);
	if (!$resul)
		Header('Location: '.$pagerror.'?herror=3'); // Error de recuperación de datos.
}
//________________________________________________________________________________________________________
?>
<HTML>
<HEAD>
	<TITLE>Administración web de aulas</TITLE>
	<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
	<LINK rel="stylesheet" type="text/css" href="../estilos.css">
	<SCRIPT language="javascript" src="../jscripts/propiedades_centros.js"></SCRIPT>
	<SCRIPT language="javascript" src="../jscripts/opciones.js"></SCRIPT>
	<SCRIPT language="javascript" src="../jscripts/validators.js"></SCRIPT>
	<?php echo '<SCRIPT language="javascript" src="../idiomas/javascripts/'.$idioma.'/propiedades_centros_'.$idioma.'.js"></SCRIPT>'?>

</HEAD>
<BODY>
<FORM  name="fdatos" action="../gestores/gestor_centros.php" method="post"> 
	<INPUT type=hidden name=opcion value="<?php echo $opcion?>">
	<INPUT type=hidden name=idcentro value=<?php echo $idcentro?>>
	<INPUT type=hidden name=identidad value=<?php echo $identidad?>>
	<P align=center class=cabeceras><?php echo $TbMsg[4]?><BR>
	<SPAN class=subcabeceras><?php echo $opciones[$opcion]?></SPAN></P>
	<TABLE  align=center border=0 cellPadding=1 cellSpacing=1 class=tabla_datos>
<!-- -------------------------------------------------------------------------------------------------------------------------------------------- -->
			<TR>
				<TH>&nbsp;<?php echo $TbMsg[5]?>&nbsp;</TH>
				<?php if ($opcion==$op_eliminacion){?>
					<TD><?php echo $nombrecentro?></TD>
				<?php }else{?>
					<TD><INPUT type=text class=cajatexto  name="nombrecentro"  style="width:350px" value="<?php echo $nombrecentro?>">
				<?php }?>
			</TR>
<!-- -------------------------------------------------------------------------------------------------------------------------------------------- -->
		<TR>
			<TH align=center>&nbsp;<?php echo $TbMsg[6]?>&nbsp;</TH>
			<?php if ($opcion==$op_eliminacion)
					echo '<TD>'.$comentarios.'</TD>';
				else
					echo '<TD><TEXTAREA   class="formulariodatos" name=comentarios rows=3 cols=66>'.$comentarios.'</TEXTAREA></TD>';
			?>
		</TR>	
<!-- -------------------------------------------------------------------------------------------------------------------------------------------- -->
               <?php  if ($opcion!=$op_eliminacion) {
echo "			<TR>\n".
     "				<TH align=center>&nbsp;".$TbMsg['DIR']."&nbsp;</TH>\n".
     "				<TD><INPUT type=text class=cajatexto  name='directorio' maxlength='50' style='width:30em' value='".$directorio."'></TD>\n".
     "			</TR>\n".
     "			<TR>\n".
     "                          <TH colspan='4' align='center'>&nbsp;<sup>*</sup>".$TbMsg['MSG_OGUNIT']."</TH>".
     "			</TR>\n";
		}
		?>
<!-- -------------------------------------------------------------------------------------------------------------------------------------------- -->
	</TABLE>
</FORM>
<?php
//________________________________________________________________________________________________________
include_once("../includes/opcionesbotonesop.php");
//________________________________________________________________________________________________________
?>
</BODY>
</HTML>
<?php
//________________________________________________________________________________________________________
//	Recupera los datos de un centro
//		Parametros: 
//		- cmd: Una comando ya operativo (con conexión abierta)  
//		- id: El identificador del centro
//________________________________________________________________________________________________________
function TomaPropiedades($cmd,$id){
	global $nombrecentro;
	global $comentarios;
        global $directorio;
	
	$rs=new Recordset; 
	$cmd->texto="SELECT * FROM centros WHERE idcentro=".$id;
	$rs->Comando=&$cmd; 
	if (!$rs->Abrir()) return(false); // Error al abrir recordset
	$rs->Primero(); 
	if (!$rs->EOF){
			$nombrecentro=$rs->campos["nombrecentro"];
			$comentarios=$rs->campos["comentarios"];
			$directorio=$rs->campos["directorio"];
		$rs->Cerrar();
		return(true);
	}
	else
		return(false);
}
?>
