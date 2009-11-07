<?
// *************************************************************************************************************************************************
// Aplicación WEB: ogAdmWebCon
// Autor: José Manuel Alonso (E.T.S.I.I.) Universidad de Sevilla
// Fecha Creación: Diciembre-2003
// Fecha Última modificación: Febrero-2005
// Nombre del fichero: controlacceso.php
// Descripción :Este fichero implementa el control de acceso a la Aplicación en todas las p�inas
// *************************************************************************************************************************************************
include_once("./includes/ctrlacc.php");
//________________________________________________________________________________________________________
$herror=0;
if (isset($_GET["herror"])) $herror=$_GET["herror"]; 
//________________________________________________________________________________________________________
?>
<HTML>
	<TITLE> Administración web de aulas</TITLE>
	<HEAD>
	<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
		<LINK rel="stylesheet" type="text/css" href="estilos.css">
	</HEAD>
	<BODY>
		<?
			echo '<SCRIPT LANGUAGE="JAVASCRIPT">'.chr(13);
			echo '	var o=window.top;'.chr(13);
			echo '	var ao=o.parent;'.chr(13);
			echo '	while (o!=ao){ // Busca la primera ventana del navegador'.chr(13);
			echo '	 ao=o;'.chr(13);
			echo '	 o=o.parent;';
			echo '	 };'.chr(13);
			echo '	ao.location="'.$urlacceso.'?herror='.$herror.'";'.chr(13);
			echo '</SCRIPT>'.chr(13);
		?>
	</BODY>
</HTML>
