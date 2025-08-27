<!DOCTYPE html>
<html data-bs-theme="dark" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="application/xml+xhtml; charset=UTF-8" />

</head>
<body style="overflow:hidden">


<style>

body{font-size: 12px !important;}

td {padding-left: 0px;padding-right: 0px;font-size: 10px !important;}


.cursor {position: fixed; top: 0; right: 0; bottom: 0; left: 0; z-index: 1; pointer-events: none;}

.hl {position: absolute; height: 1px; left: 0; right: 0; background: cyan;}
.vt {position: absolute; top: 0; bottom: 0; width: 2px; background: cyan;}

thead th {background:#b6b6ba; color:black;text-align: center;min-width:1px;
    border: 0px solid red;line-height:1; padding-left: 11px!important; margin:10px; font-size: 10px !important; font-family:monospace}

.dt-head-center {text-align: center;color: #222222;min-width: 70px;
    border: solid .3px black;}

.dtfc-top-blocker{
        background-color: transparent !important;
}

input {
    width: 100%;}

.btn {
    font-size: 10px !important;font-family:monospace
}



.page-link {
    font-size: 10px !important;font-family:monospace
}


.dtsb-searchBuilder {
    font-size: 10px; display:block !important;font-family:monospace
}

table.dataTable tbody th, table.dataTable tbody td {
    padding: 3px 2px;
}

</style>


<link href="https://https://cdn.datatables.net/2.3.2/css/dataTables.dataTables.css">
<link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.3.0/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-9ndCyUaIbzAi2FUVXJi0CjmCapSmO7SnpJef0486qhLnuZ2cdeRhO02iuK6FUUVM" crossorigin="anonymous">
<link href="https://cdn.datatables.net/v/bs5/jq-3.7.0/jszip-3.10.1/dt-2.3.2/af-2.7.0/b-3.2.4/b-colvis-3.2.4/b-html5-3.2.4/b-print-3.2.4/cr-2.1.1/cc-1.0.7/date-1.5.6/fc-5.0.4/fh-4.0.3/kt-2.12.1/r-3.0.5/rg-1.5.2/rr-1.5.0/sc-2.4.3/sb-1.8.3/sp-2.3.4/sl-3.0.1/sr-1.4.1/datatables.min.css" rel="stylesheet" integrity="sha384-qJ7Hur6EAjk21mqGeSZEcxev96zkLWAy/5+FOdE/KwM1ggLqtsrIbdQEb04dOG2Q" crossorigin="anonymous">
 
<script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.3.0/js/bootstrap.bundle.min.js" integrity="sha384-geWF76RCwLtnZ8qwWowPQNguL3RmwHVBC9FhGdlKrxdiJJigb/j/68SIy3Te4Bkz" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/pdfmake.min.js" integrity="sha384-VFQrHzqBh5qiJIU0uGU5CIW3+OWpdGGJM9LBnGbuIH2mkICcFZ7lPd/AAtI7SNf7" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/vfs_fonts.js" integrity="sha384-/RlQG9uf0M2vcTw3CX7fbqgbj/h8wKxw7C3zu9/GxcBPRKOEcESxaxufwRXqzq6n" crossorigin="anonymous"></script>
<script src="https://cdn.datatables.net/v/bs5/jq-3.7.0/jszip-3.10.1/dt-2.3.2/af-2.7.0/b-3.2.4/b-colvis-3.2.4/b-html5-3.2.4/b-print-3.2.4/cr-2.1.1/cc-1.0.7/date-1.5.6/fc-5.0.4/fh-4.0.3/kt-2.12.1/r-3.0.5/rg-1.5.2/rr-1.5.0/sc-2.4.3/sb-1.8.3/sp-2.3.4/sl-3.0.1/sr-1.4.1/datatables.min.js" integrity="sha384-1YleQc/kbN4EHO6pxWhTGrOIlQmKPo85juBfEOFhV2HExKWuw5lHDD/6Y132EPw2" crossorigin="anonymous"></script>

<!--
<link href="/mnt/01DA68749ECDBF70/1-workdir/lampAID/github-lampAID/DataTables/datatables.css" rel="stylesheet">
<script src="/mnt/01DA68749ECDBF70/1-workdir/lampAID/github-lampAID/DataTables/datatables.js"></script>

-->

<script>


let toolbar = document.createElement('div');
toolbar.innerHTML = '<b>LampAID interactive table results</b>';


let spacer = document.createElement('div');
spacer.innerHTML = '<b>   </b>';

$(document).ready( function () {        

        $('#myTable thead tr:eq(1)').clone(true).appendTo('#myTable thead');
        $('#myTable thead tr:eq(1) th').each(function(i) {
            var title = $(this).text();
            $(this).html('<input size="7px" type="text" placeholder="Search" />');

            $('input', this).on('keyup change', function() {
                if (table.column(i).search() !== this.value) {
                    table
                        .column(i)
                        .search(this.value)
                        .draw();
                }
            });
        });
  
let table = $('#myTable').DataTable({


    buttons: [
    {extend: 'print',text: 'Print',},
    {extend: 'csv',text: 'Csv',},
    {extend: 'copy',text: 'Copy',},
    {extend: 'pdfHtml5',
    text: 'PDF current page',
    orientation: 'landscape',
    
    pageSize: 'B0',
    customize: function (doc) {        
            doc.defaultStyle.fontSize = 10;
            doc.defaultStyle.font = 'Roboto';},
    exportOptions: {
    modifier: {
    page: 'current',
    }, //modifier
  
    }, //export
    
    }], //buttons

language: {
        searchBuilder: {
            title: '<br>Advanced search<br> '
        }
    },
    
    
     layout: {

          
     bottomStart: null,bottomEnd:null,
     topStart: null,topEnd:null,
     
     top2:toolbar,
     top1:['paging','pageLength','info','search'],

     topStart: [spacer,'searchBuilder',spacer,],
     topEnd: [spacer,'buttons',spacer,{buttons: ['colvis']},],
     },

      colReorder: true,
      order: [[5,6, 'desc']],
      fixedColumns: {
       start: 2
      },

      scrollX: true,
      scrollY: '65vh',
      scrollCollapse: true,

      processing: true,
      serverSide: false,

      paging: true,
      pageLength: 50,
      lengthMenu: [[20,50,100, 250, 1000, 2500, -1], [20,50,100, 250, 1000, 2500, 'All']],
      columnDefs: [


      // Center align text
      { className: "dt-head-center", targets: [ '_all' ] },
      { className: "dt-body-center", targets: [ 2,3,4,5,6,7 ] },
      // Left align body text
      { className: "dt-body-left", targets: [ 0,1 ] },
      
      ],
      ordering: true,
      orderCellsTop: true,
      autoWidth: true,
      fixedHeader: false,
   initComplete: function() {   }
  });


} );


</script>

<div class='cursor' style='z-index:4'>
<div class='vt'></div>
<div class='hl'></div>
</div>

<script>
const cursorVT = document.querySelector('.vt')
const cursorHL = document.querySelector('.hl')
document.addEventListener('mousemove', e => {
cursorVT.setAttribute('style', `left: ${e.clientX}px;`)
cursorHL.setAttribute('style', `top: ${e.clientY}px;`)
})

</script>

<pre style="margin:5px;overflow: hidden;">

<table id='myTable' class="table table-striped" cellspacing="0" style="font-weight: bold;">

<thead style="text-align: center; border: 30px;">
