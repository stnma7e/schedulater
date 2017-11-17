import $ from 'jquery';
import timepicker from 'timepicker';
import React from 'react';

import ActiveInstructorFilter from './containers/activeInstructorFilter.js';

export class Filter extends React.Component {
    constructor(props) {
        super(props)

        $("#start_time").on('click', () => {
            console.log("HERE")
            this.props.changeStartTime($("#start_time").timepicker('getTime').toTimeString())
        })
        $("#end_time").on('click', () => {
            console.log("HERE")
            this.props.changeEndTime($("#end_time").timepicker('getTime').toTimeString())
        })
    }
    componentDidMount() {
        $("#start_time").timepicker({
            minTime: "7:00am",
            maxTime: "10:00pm",
            step: 15
        });
        $("#end_time").timepicker({
            minTime: "7:00am",
            maxTime: "10:00pm",
            step: 15
        });
    }

    render() {
        return (
            <div className="filterBlock cell">
        <div className="card">
          <div className="card-divider">
            <h6>{this.props.filterType}</h6>
          </div>
          <div className="card-section">
            {this.props.children}
          </div>
        </div>
      </div>
        )
    }
}

export default class AllFilters extends React.Component {
    render() {
        return (
            <div id="filters" className={this.props.className}>
        <h5>Filters:</h5>
        <hr/>
        <div className="grid-x grid-padding-x small-up-3 large-up-1">


          <Filter filterType="Time">
            <div className="cell small-6">
              Start
              <input
                className="ui-timepicker-input"
                type="text"
                id="start_time"
                defaultValue="08:00"
              />
            </div>
            <div className="cell small-6">
              End
              <input
                className="ui-timepicker-input"
                type="text"
                id="end_time"
                defaultValue="19:00"
                onChange={() => {console.log("HERE")}}
              />
            </div>
          </Filter>

          <Filter filterType="Credit Hours">
            <div className="cell small-6">
              Minimum #
              <input
                type="number"
                id="minHours"
                value={this.props.minHours}
                onChange={(event) => {this.props.changeCreditHours(true, event)}}
              />
            </div>
            <div className="cell small-6">
              Maximum #
              <input
                type="number"
                id="maxHours"
                value={this.props.maxHours}
                onChange={(event) => {this.props.changeCreditHours(false, event)}}
              />
            </div>
          </Filter>

          <ActiveInstructorFilter />

        </div>
      </div>
        )
    }
}