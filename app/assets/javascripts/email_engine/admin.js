window.EmailEngine = {
  graph: {},
  pie: {},
  totals: {},

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
      return '/email/admin/sent.json?'+$.param({last: $('input#last').val(), interval: $('input#interval').val() });
    },

    load: function() {
      $.ajax({
        url: EmailEngine.list.url(),
        type: 'GET',
        complete: function( data ) {
          console.log(data);
           // data = $.map(data.responseText.split("\n"), function(d){ return [d.split(",")] });
           // window['EmailEngineData'] = data;
           // EmailEngine.chart.load({
           //    data:{
           //      rows: data,
           //      xFormat: '%Y-%m-%dT%H:%M:%SZ',
           //      x: 'x',
           //    }
           // });
        }
      });
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
