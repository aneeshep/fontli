$(document).ready(function() {
  // Create the chart
  if($('#users_statistics').length) {
    var facebookData = [];
    var twitterData = [];

    $.getJSON('/admin/twitter_users', function( data ) { 
      $.each( data, function( key, val ) {
        var twitter_user = {};
        twitter_user['name'] = key;
        twitter_user.y = val.total_count;
        twitter_user.drilldown = 'twitter_' + key;
        twitterData.push(twitter_user);
	      
        var twitter_drilldown_user = {};
        twitter_drilldown_user.id = 'twitter_' + key;
        twitter_drilldown_user.name = key
        twitter_drilldown_user.data = val.data;
        options.drilldown.series.push(twitter_drilldown_user);
      });
    });
	
    $.getJSON('/admin/facebook_users', function( data ) { 
      $.each( data, function( key, val ) {
	var fb_user = {};
	fb_user.name = key;
	fb_user.y = val.total_count;
	fb_user.drilldown = 'facebook_' + key;
	facebookData.push(fb_user);
	      
	var fb_drilldown_user = {};
	fb_drilldown_user.id = 'facebook_' + key;
	fb_drilldown_user.name = key
	fb_drilldown_user.data = val.data;
	options.drilldown.series.push(fb_drilldown_user);
	chart = new Highcharts.Chart(options);
      });
    });
    var options = {
      chart: {
        renderTo: 'users_statistics',
	type: 'column'
      },
      title: {
	text: 'Users Statistics'
      },
      xAxis: { 
	type: 'category'
      },
      legend: {
	enabled: true
      },
      plotOptions: { 
	series: 
	{ borderWidth: 0,
	  dataLabels:
	  { 
	    enabled: true,
	    style: 
	      {
                color: 'white',
                textShadow: '0 0 2px black, 0 0 2px black'
	      }
	  },
	  stacking: 'normal'
	}
      },
      series: [ { name: 'Twitter', data: twitterData },
		{ name: 'Facebook', data: facebookData } ],
      drilldown: {
	activeDataLabelStyle: {
          color: 'white',
          textShadow: '0 0 2px black, 0 0 2px black'
	},
	series: []
      }
    }
  }
});
