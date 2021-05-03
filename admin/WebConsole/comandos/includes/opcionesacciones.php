<?php
// *************************************************************************************************************************************************
// Aplicación WEB: ogAdmWebCon
// Autor: José Manuel Alonso (E.T.S.I.I.) Universidad de Sevilla
// Fecha Creación: Año 2009-2010
// Fecha Última modificación: Abril-2010
// Nombre del fichero: opcionesacciones.php
// Descripción : 
//		Opciones comunes para la ejecución de comandos
// *************************************************************************************************************************************************
?>

<P align=center><span align=center class=subcabeceras><?php echo $TbMsgAux[0] ?></span></P>
<?php if ($ambito !=16 ){ ?>
	<INPUT type="hidden" name="ambito" value="<?php echo $ambito?>">
<?php } ?>
<?php if($idcomando!=10){?>
	<TABLE align=center>
		<TR>
			<TD><IMG border=0 style="cursor:pointer" src="../images/boton_aceptar_<?php echo $idioma ?>.gif" onclick="confirmar()" ></TD>
		</TR>
	</TABLE>
	<BR>
<?php }?>	
<TABLE align=center  class=opciones_ejecucion BORDER=0>
<!-------------------------------------------------AGP-------------------------------------------------------------------------------->
	<TR>
		<TD colspan=4>
		<?php if ($funcion == "RestaurarImagen" || $funcion == "RestaurarImagenCache" ){ ?>
			<TABLE id="tabla_conf" class="tabla_listados" align=right border="2" cellpadding="1" cellspacing="1">
				<TR>
					<TH colspan=3><?php echo $TbMsgAux[13]; ?>&nbsp;</TH>
					<TH align="center"><INPUT name=sw_ejsis type=checkbox checked value=0></TH>
					
				</TR>
			</TABLE>
		<?php } ?>
		</TD>
	</TR>	
	<!-------------------------------------------------------------------------------------------------------------------------------->
		 <TR HEIGHT=5><TD colspan=4><HR></TD></TR>
	<!-------------------------------------------------------------------------------------------------------------------------------->
<!-------------------------------------------------AGP-------------------------------------------------------------------------------->
	<TR>
		<TD><INPUT name=sw_ejya type=checkbox checked></TD>
		<TD colspan=2> <?php echo $TbMsgAux[1] ?> &nbsp; </TD>
		<TD rowspan="3">
		</TD>
	</TR>
	<TR>
	  <TD>&nbsp; </TD>
	  <TD><INPUT name=sw_seguimiento type=radio value=1></TD><TD><?php echo $TbMsgAux[2] ?>&nbsp;</TD>
    </TR>
	<TR>
		<TD>&nbsp; </TD>
		<TD><INPUT checked name=sw_seguimiento type=radio value=0></TD><TD><?php echo $TbMsgAux[3] ?>&nbsp;</TD>
	</TR>
	<!-------------------------------------------------------------------------------------------------------------------------------->
		 <TR HEIGHT=5><TD colspan=4><HR></TD></TR>
	<!-------------------------------------------------------------------------------------------------------------------------------->
	<TR>
		<TD><INPUT name=sw_ejprg type=checkbox></TD>
		<TD colspan=3><?php echo $TbMsgAux[4] ?>&nbsp;</TD>
	</TR>	
	<!-------------------------------------------------------------------------------------------------------------------------------->
		 <TR HEIGHT=5><TD colspan=4><HR></TD></TR>
	<!-------------------------------------------------------------------------------------------------------------------------------->
	 <TR>
	  <TD><INPUT  onclick="clic_mkprocedimiento(this)"  name=sw_mkprocedimiento type=checkbox></TD>
	  <TD colspan=3><?php echo $TbMsgAux[5] ?>&nbsp;</TD></TR>

	 <TR>
	  <TD>&nbsp; </TD>
	  <TD><INPUT onclick="clic_nwprocedimiento(this)"  name=sw_procedimiento type=radio value=0></TD>
	  <TD><?php echo $TbMsgAux[6] ?>&nbsp; </TD>
	 <TD><INPUT onclick="clic_nomprocedimiento(this)" style="FONT-FAMILY:Arial, Helvetica, sans-serif;FONT-SIZE: 11px" name=nombreprocedimiento style="HEIGHT: 22px; WIDTH: 275px"></TD></TR>
	 
	 <TR>
	  <TD>&nbsp; </TD>
	  <TD><INPUT onclick="clic_exprocedimiento(this)" name=sw_procedimiento type=radio value=1></TD>
	  <TD><?php echo $TbMsgAux[7] ?>&nbsp;</TD>
	  <TD><?php echo HTMLSELECT($cmd,$idcentro,'procedimientos',0,'idprocedimiento','descripcion',275,"procedimientoexistente");?></TD></TR>
	  
	 <TR>
	  <TD>&nbsp; </TD>
	  <TD>&nbsp; </TD>
	  <TD><?php echo $TbMsgAux[8] ?>&nbsp;</TD>
	  <TD><INPUT maxlength=3  style="FONT-FAMILY:Arial, Helvetica, sans-serif;FONT-SIZE: 11px;WIDTH:30px" name=ordprocedimiento type=text value=""></TD></TR>
	<!-------------------------------------------------------------------------------------------------------------------------------->
		 <TR><TD colspan=4 HEIGHT="10">&nbsp; <HR></TD></TR>
	<!-------------------------------------------------------------------------------------------------------------------------------->
	 <TR>
	  <TD><INPUT  onclick="clic_mktarea(this)"  name=sw_mktarea type=checkbox></TD>
	  <TD colspan=3><?php echo $TbMsgAux[9] ?>&nbsp;</TD></TR>

	 <TR>
	  <TD>&nbsp; </TD>
	  <TD><INPUT onclick="clic_nwtarea(this)"  name=sw_tarea type=radio value=0></TD>
	  <TD><?php echo $TbMsgAux[10] ?>&nbsp;</TD>
	 <TD><INPUT onclick="clic_nomtarea(this)" style="FONT-FAMILY:Arial, Helvetica, sans-serif;FONT-SIZE: 11px" name=nombretarea style="HEIGHT: 22px; WIDTH: 275px"></TD></TR>
	 
	 <TR>
	  <TD>&nbsp; </TD>
	  <TD><INPUT onclick="clic_extarea(this)" name=sw_tarea type=radio value=1></TD>
	  <TD><?php echo $TbMsgAux[11] ?>&nbsp;</TD>
	  <TD><?php echo HTMLSELECT($cmd,$idcentro,'tareas',0,'idtarea','descripcion',275,"tareaexistente");?></TD></TR>

	 <TR>
	  <TD>&nbsp; </TD>
	  <TD>&nbsp; </TD>
	  <TD><?php echo $TbMsgAux[12] ?>&nbsp;</TD>
	  <TD><INPUT maxlength=3  style="FONT-FAMILY:Arial, Helvetica, sans-serif;FONT-SIZE: 11px;WIDTH:30px" name=ordtarea type=text value=""></TD></TR>
	<!-------------------------------------------------------------------------------------------------------------------------------->
	</TABLE>
</FORM>


