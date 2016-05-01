window.EmailEngine = {
  graph: {},
  pie: {},
  totals: {},
  
  reload: function(){
    EmailEngine.graph.load({url: EmailEngine.statsUrl()});
    EmailEngine.list.load({url: EmailEngine.list.url()});
  },

  statsUrl: function(){
    return '/email/admin/stats?'+$.param({last: $('input#last').val(), interval: $('input#interval').val() });
  },

  generatePie: function(){
    var _this = this;
    var colors ={}
    colors['Sent ('+ _this.totals['sent'] + ')'] = '#FFDD00'
    colors['Open ('+ _this.totals['open'] + ')'] = '#0FD132'
    colors['Click ('+ _this.totals['click'] + ')'] = '#79B6E8'
    colors['Bounce ('+ _this.totals['bounce'] + ')'] = '#FF9500'
    colors['Complaint ('+ _this.totals['complaint'] + ')'] = '#E82727'
    this.pie= c3.generate({
      bindto: '#pie',
      data: {
        type: 'pie',
        columns: [
           ['Sent ('+ _this.totals['sent'] + ')', _this.totals['sent']],
           ['Open ('+ _this.totals['open'] + ')', _this.totals['open']],
           ['Click ('+ _this.totals['click'] + ')', _this.totals['click']],
           ['Bounce ('+ _this.totals['bounce'] + ')', _this.totals['bounce']],
           ['Complaint ('+ _this.totals['complaint'] + ')', _this.totals['complaint']]
        ],
        colors: colors
      }  
    })
  },
  
  generateGraph: function(){
    var _this = this;
    this.graph= c3.generate({
      bindto: '#graph',
      data: {
        //rows: [['x','sent','open','click','bounce','complaint']],
        url: EmailEngine.statsUrl(),
        xFormat: '%Y-%m-%dT%H:%M:%SZ',
        x: 'x',
        colors: {
          sent: '#FFDD00',
          open: '#0FD132',
          click: '#79B6E8',
          bounce: '#FF9500',
          complaint: '#E82727'
        },
      },
      onrendered: function () { 
        // RENDER PIE CHART
        _this.sumChartData(_this.graph.data());
      },
      axis: {
        x: {
          type: 'timeseries',
          tick: {
            format: '%H:%M:%S'
          }
        }
      }
    })
  },

  sumChartData: function(data=[]){
    var _this = this;
    _this.totals = { sent: 0, unread: 0, open: 0, click: 0, bounce: 0, complaint: 0 };
    data.forEach(function(el){
      _this.totals[el.id] = 0;
      el.values.forEach(function(el1){ 
        _this.totals[el.id]+=parseFloat(el1.value) || 0;
      });
    });
    _this.generatePie();
  },

  search: function(el) {
    if(event.keyCode == 13) {
      document.location = document.location.href.split('?')[0]+"?query="+encodeURIComponent(el.value);
    }
  },
  list:{
    url: function(){
      return '/email/admin.json?'
    },

    load: function() {
      var _this = this;
      $.ajax({
        url:  '/email/admin.json',
        type: 'GET',
        data:{
          type: $('#type').val(),
          last: $('input#last').val(),
          interval: $('input#interval').val()
        },
        complete: function( data ) {
          $('table#list').find("tr:gt(1)").remove();
           data = $.map(JSON.parse(data.responseText).reverse(), function(el){
             _this.format(el)
          });
        }
      });
    },
    
    format: function(el){
      var row = $("<tr style='display:none;'>").append($('<td>').append($("<div class='state "+el.state+"' title='"+el.state+"'/>")))
      $(row).append($("<td class='visible-lg'>").append(el.id))      
      $(row).append($("<td>").append($('<div>').html(el.to)).append($('<div>').addClass('visible-xs visible-sm').html($('<small>').html(el.subject))))
      $(row).append($("<td class='visible-lg visible-md'>").append(el.subject))
      $(row).append($("<td class='visible-lg visible-md'>").append(el.sent_at))
      $(row).append($("<td>").append($("<a href='/email/admin/"+el.id+"'>").addClass('btn btn-default btn-sm').text('VIEW')))
      $(row).insertAfter('table#list .tabs').fadeIn(200);
    }
  }
}


/*function load(){
  console.log("load")
  window['EmailEngineData'] = {};
  $.ajax({
    url: EmailEngine.url(),
    type: 'GET',
    complete: function( data ) {
       data = $.map(data.responseText.split("\n"), function(d){ return [d.split(",")] });
       window['EmailEngineData'] = data;
       EmailEngine.chart.load({
          data:{
            rows: data,
            xFormat: '%Y-%m-%dT%H:%M:%SZ',
            x: 'x',
          }
       });
    }
  });
}
window.EmailEngine.load = load;*/
