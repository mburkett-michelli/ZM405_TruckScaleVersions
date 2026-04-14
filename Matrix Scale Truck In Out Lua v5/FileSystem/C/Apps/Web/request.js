function makeRequest(url, callback, item, id)
{
   var http_request = false;

   url = url + "?" + item + "=" + id;

   data_received = 1;
   if (window.XMLHttpRequest)
   { // Mozilla, Safari,...
      http_request = new XMLHttpRequest();
      if (http_request.overrideMimeType)
      {
         http_request.overrideMimeType('text/xml');
      }
   }
   else if (window.ActiveXObject)
   { // IE
      try
      {
         http_request = new ActiveXObject("Msxml2.XMLHTTP");
      }
      catch (e)
      {
         try
         {
            http_request = new ActiveXObject("Microsoft.XMLHTTP");
         }
         catch (e)
         {
         }
      }
   }

   if (!http_request)
   {
      alert('Giving up :( Cannot create an XMLHTTP instance');
      return false;
   }

   http_request.onreadystatechange = function() { callback(http_request, id); };
   http_request.open('GET', url, true);
   http_request.send(null);
}


sfHover2 = function() {
	var navthree = document.getElementById("lnv");
	if (navthree){
		var sfEls2 = document.getElementById("lnv").getElementsByTagName("LI");
		for (var i=0; i<sfEls2.length; i++) {
			sfEls2[i].onmouseover=function() {
				this.className+=" sfhover";
				hideselects('hidden');
			}
			sfEls2[i].onmouseout=function() {
				this.className=this.className.replace(new RegExp(" sfhover\\b"), "");
				hideselects('visible');
			}
		}
	}
}

function hideselects(state) {
	for(i=0;i<document.forms.length;i++){ // if there are forms on the page
		frm = document.forms[i];
		var inputs = frm.getElementsByTagName("SELECT");
		for (j=0;j<inputs.length;j++){
			inputs[j].style.visibility = state;
		}
	}
}

