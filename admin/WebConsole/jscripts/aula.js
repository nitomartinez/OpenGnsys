﻿// *************************************************************************************************************************************************
// Libreria de scripts de Javascript
// Autor: José Manuel Alonso (E.T.S.I.I.) Universidad de Sevilla
// Fecha Creación: 2009-2010
// Fecha Última modificación: Marzo-2006
// Nombre del fichero: aula.js
// Descripción : 
//		Este fichero implementa las funciones javascript del fichero aulas.php
// *************************************************************************************************************************************************
	function NodoAux(){
		this.idambito=0;								
		this.ambito=0;
		this.litambito=null; 
		this.nombreambito=null;

		this.toma_identificador= function(){
			return(idambito);
		};
		this.toma_sufijo= function(){
			return(litambito);
		};
		this.toma_infonodo= function(){
			return(nombreambito);
		}
		// Fin de la clase
}
currentNodo=new NodoAux();
//________________________________________________________________________________________________________
function nwmenucontextual(o,idmnctx){
	var menuctx=document.getElementById(idmnctx); // Toma objeto DIV
	muestra_contextual(ClickX,ClickY,menuctx); // muestra menu
	Toma_Datos(o);
}
//________________________________________________________________________________________________________
//	
//	Toma datos
//________________________________________________________________________________________________________
function Toma_Datos(o){
	var identificador=o.getAttribute("nod");
	litambito=identificador.split("-")[0];
	idambito=identificador.split("-")[1];
	nombreambito=o.getAttribute("value");
	currentNodo.idambito=idambito;
	currentNodo.litambito=litambito;
	currentNodo.nombreambito=nombreambito;
}
//________________________________________________________________________________________________________
function wactualizar_ordenadores(o){
	Toma_Datos(o);
 	actualizar_ordenadores();
}
//________________________________________________________________________________________________________
//	
//	Refresca la visualizaci� del estado de los ordenadores(Clientes rembo y clientes Windows o Linux) 
//________________________________________________________________________________________________________
function Sondeo(){
	reset_contextual(-1,-1); // Oculta menu contextual
	var ambito=document.fcomandos.ambito.value; // Ámbito de aplicación
	var idambito=document.fcomandos.idambito.value; // Identificador del ámbito
	var wurl="../principal/sondeo.php";
	var prm="ambito="+ambito+"&idambito="+idambito+"&sw=1"; // La primera vez se manda sondeo a los clientes
	CallPage(wurl,prm,"retornoSondeo","POST");
	setTimeout("respuestaSondeo();",100); 	
}
//______________________________________________________________________________________________________
function retornoSondeo(resul){
/*
	if(resul==1)
 		alert(TbMsg[11]);
	else
		alert(TbMsg[12]);
*/
}
//________________________________________________________________________________________________________
function respuestaSondeo(){
	var ambito=document.fcomandos.ambito.value; // Ámbito de aplicación
	var idambito=document.fcomandos.idambito.value; // Identificador del ámbito
	var wurl="../principal/sondeo.php";
	var prm="ambito="+ambito+"&idambito="+idambito+"&sw=2"; // Las siguientes veces se consulta sólo la tabla de clientes
	CallPage(wurl,prm,"retornorespuestaSondeo","POST");
	setTimeout("respuestaSondeo();",5000); 	
}
//______________________________________________________________________________________________________
function retornorespuestaSondeo(resul)
{

	if(resul.length>0){
		var ip=""; // Dirección IP del ordenador
		var so=""; // Sistema operativo activo
		var objOrd=null; // Objeto ordenador
		var imgOrd="";
		var cadena=resul.split(";"); // Trocea la cadena devuelta por el servidor de adminsitración
		for (var i=0;i<cadena.length;i++){
			var dual=cadena[i].split("/");
			ip=dual[0].replace(/\n*/,"");
			so=dual[1];
			objOrd=document.getElementById(ip);
			if(objOrd){ // Si existe el objeto
					imgOrd=soIMG(so); // Toma url de la imagen según su s.o.
					if(objOrd.sondeo!=so){ // Si es distinto al que tiene ...se cambia la imagen
						objOrd.src="../images/"+imgOrd;
						objOrd.sondeo=imgOrd;
					}
			}		
		}
	}
}
//______________________________________________________________________________________________________
function soIMG(so)
{
	var MimgOrdenador="";
	switch(so){
		case 'INI':
			MimgOrdenador="ordenador_INI.png";  // Iniciando cliente
			break;
		case 'BSY':
			MimgOrdenador="ordenador_BSY.png";  // Cliente ocupado
			break;
		case 'OPG':
			MimgOrdenador="ordenador_OPG.png";  // Cliente OpenGnsys
			break;
		case 'WIN':
		case 'WXP':
			MimgOrdenador="ordenador_WIN.png"; // Windows
			break;
		case 'WINS':
			MimgOrdenador="ordenador_WINS.png"; // Sesión Windows
			break;
		case 'LNX':
			MimgOrdenador="ordenador_LNX.png"; // Linux
			break;
		case 'LNXS':
			MimgOrdenador="ordenador_LNXS.png"; // Sesión Linux
			break;
		case 'OSX':
			MimgOrdenador="ordenador_OSX.png"; // macOS
			break;
		case 'VDI':
			MimgOrdenador="ordenador_VDI.png"; // Virtual
			break;
		case 'WOL_SENT':
			MimgOrdenador="ordenador_WOL_SENT.png"; // Wol enviado
			break;
		default:
			MimgOrdenador="ordenador_OFF.png"; // Apagado
			break;
	}
	return(MimgOrdenador);
}

