import $ from 'jquery';
import fullCalendar from 'fullcalendar';
import timepicker from 'timepicker';
import React from 'react';
import ReactDOM from 'react-dom';
import {
  Foundation,
  Label
} from 'react-foundation';
import {DataTable} from 'datatables.net';
import {Button} from 'datatables.net-buttons-zf';
import {Select} from 'datatables.net-select';
require('foundation-sites');

function change_sched(button) {
  if (typeof get_sched.sched_number == 'undefined') {
    get_sched.sched_number = 0;
  }

  if (button == 'next-button' && get_sched.sched_number < get_sched.sched_count - 1) {
    get_sched.sched_number += 1;
  } else if (button == 'last-button' && get_sched.sched_number > 0) {
    get_sched.sched_number -= 1;
  }

  console.log(get_sched.sched_number);

  $('#calendar').fullCalendar('refetchEvents')
}

function get_sched(start, end, timezone, callback) {
  if (typeof get_sched.sched_number == 'undefined') {
    get_sched.sched_number = 0;
  }

  if (typeof get_sched.sched_list == 'undefined' || get_sched.refetch) {
    get_sched.refetch = false;
    get_sched.sched_number = 0;

    $.ajax({
      url:'/courses',
      type: "POST",
      data:JSON.stringify(get_sched.data),
      success: function(result) {
        var courses = JSON.parse(result);
        get_sched.sched_list = courses.schedule;
        get_sched.sched_count = courses.sched_count;
        console.log(courses.sched_count);
        callback(courses.schedule[get_sched.sched_number])
      }
    });
  } else {
    callback(get_sched.sched_list[get_sched.sched_number])
  }

}


function getCookie(cname) {
  var name = cname + "=";
  var decodedCookie = decodeURIComponent(document.cookie);
  var ca = decodedCookie.split(';');
  for(var i = 0; i <ca.length; i++) {
      var c = ca[i];
      while (c.charAt(0) == ' ') {
          c = c.substring(1);
      }
      if (c.indexOf(name) == 0) {
          return c.substring(name.length, c.length);
      }
  }
  return "";
}

$(document).one('ready', function() {
  $('#calendar').last_width = $(window).width();
})
$(document).ready(function() {
  $('#calendar').fullCalendar({
    defaultView: 'agendaWeek',
    minTime: "8:00:00",
    maxTime: "22:00:00",
    allDaySlot: false,
    header: false,
    defaultDate: '2000-01-07',
    columnFormat: 'dddd',
    timezone: "UTC",
    firstDay: 1,
    aspectRatio: 2.6*(this.last_width/1008),
    windowResize: function(view) {
      var multiplier = $(window).width() / $('#calendar').last_width;
      $('#calendar').fullCalendar({aspectRatio: 2.6*multiplier})
    },
    events: get_sched
  })


  $("#selected_classes").DataTable({
    dom: 'Bfrtip',
    select: {
      style: 'os'
    },
    buttons : [
      {
        text: 'Remove classes',
        action: function() {
          $('#selected_classes').DataTable().rows({ selected: true }).remove().draw();
        }
      },
      {
        text: 'Send classes',
        action: function() {
          var table = $('#selected_classes').DataTable();
          var rows = table.data();
          var titles = new Array();
          for (var i=0; i< rows.length; i++) {
            titles.push(rows[i][2]); // course title
          }

          var start_time = $('#start_time').timepicker('getTime').toTimeString();
          var end_time   = $('#end_time').timepicker('getTime').toTimeString();
          var times = {
            column: "daytimes",
            exceptions: [start_time+","+end_time],
            allowed: true,
          }

          console.log(titles);
          get_sched.data = {
            courses: titles,
            filters: [times]
          }
          get_sched.refetch = true;
          console.log(get_sched.data);
          $('#calendar').fullCalendar('refetchEvents');
        }
      }
    ]
  });

  $("#subject").change(function() {
    $("#subject option:selected").each(function() {
      var subject = $(this).text();
      $.ajax({
        url: '/courses/' + subject,
        type: 'GET',
        success: function(result) {
          var div = document.getElementById('class_list');
          div.innerHTML = result;
          $('#class_list_table').DataTable({
            dom: 'Bfrtip',
            select: {
              style: 'os'
            },
            buttons: [
              {
                text: 'Add classes',
                action: function() {
                  var rows = this.rows({ selected: true }).every(function(rowIdx, tableLoop, rowLoop) {
                      $("#selected_classes").DataTable().row.add(this.data()).draw();
                  });
                }
              }
            ]
          });
        }
      })
    })
  })

  $("#start_time").timepicker({
    minTime: "7:00am",
    maxTime: "10:00pm",
    step: 15});
  $("#end_time").timepicker({
    minTime: "7:00am",
    maxTime: "10:00pm",
    step: 15});

  $('.sched_button').click(function() {
    change_sched(this.id)
  });

  ReactDOM.render(
    (<div className="label-basics-example">
      <Label>React was here.</Label>
    </div>),
    document.getElementById('root')
  );
})
