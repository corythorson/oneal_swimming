/** @jsx React.DOM */

var React = require('react');
var DateTimeField = require('react-bootstrap-datetimepicker');
var Router = require('react-router');
var Link = Router.Link;
var ScheduleCell = require('./schedule-cell');
var moment = require('moment');
var _ = require('lodash');

var Scheduler = module.exports = React.createClass({

  getInitialState: function() {
    return {
      currentUser: {},
      currentDate: new Date(),
      interval: 'day',
      intervalNumber: 1,
      intervalName: 'days',
      instructors: [],
      timeSlots: [],
      events: {}
    }
  },

  componentWillMount: function() {
    var date = new Date();
    if (this.props.params.date) {
      date = moment(this.props.params.date).toDate();
    }
    this.setState({ currentDate: date });
  },

  componentDidMount: function() {
    //this.loadCurrentUser();
    this.loadEvents();
  },

  _handleToday: function() {
    this.setState({ currentDate: new Date() }, this.loadEvents);
  },

  _handleIncrementDate: function() {
    var newDate = moment(this.state.currentDate).add(1, 'days');
    //Router.replaceWith('s', { date: newDate });
    this.setState({ currentDate: newDate }, this.loadEvents);
  },

  _handleDecrementDate: function() {
    var newDate = moment(this.state.currentDate).add(-1, 'days');
    //Router.replaceWith('s', { date: newDate });
    this.setState({ currentDate: newDate }, this.loadEvents);
  },

  _handleChangeInterval: function(interval, number, name) {
    this.setState({
      interval: interval,
      intervalNumber: number,
      intervalName: name
    });
  },

  _handleDatePickerChange: function(newDate) {
    this.setState({ currentDate: newDate }, this.loadEvents);
  },

  _renderInstructor: function(instructor) {
    return (
      <tr>
        <td className="Instructor">
          <img src={instructor.avatar} className="instructor-image img-responsive img-circle" />
          <span>{instructor.first_name}</span>
        </td>
      </tr>
    );
  },

  _renderInstructorSchedule: function(instructor) {
    var d = moment(this.state.currentDate).format('YYYY-MM-DD');
    return (
      <tr>
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-08-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-08-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-08-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-09-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-09-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-09-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-10-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-10-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-10-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-11-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-11-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-11-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-12-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-12-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-12-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-13-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-13-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-13-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-14-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-14-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-14-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-15-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-15-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-15-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-16-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-16-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-16-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-17-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-17-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-17-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-18-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-18-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-18-40'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-19-00'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-19-20'])} />
        <ScheduleCell loadEvents={this.loadEvents} currentUser={this.state.currentUser} timeSlot={(instructor.time_slots[d + '-19-40'])} />
      </tr>
    )
  },

  render: function() {
    var title = moment(this.state.currentDate).format('ddd, MMM D YYYY');
    var dtfValue = moment(this.state.currentDate);
    return (
      <div className="Scheduler">
        <div className="Scheduler__Header">
          <div className="row">
            <div className="col-sm-6 text-center-xs Scheduler__Header__Title">{title}</div>
            <div className="col-sm-6 text-right">
              <button className="btn btn-default btn-rm" onClick={this._handleToday}>Today</button>
              <div id="dateTimeField-wrapper">
                <DateTimeField
                  dateTime={dtfValue}
                  format="YYYY-MM-DD"
                  viewMode="date"
                  inputFormat="MM/DD/YYYY"
                  onChange={this._handleDatePickerChange}
                  />
              </div>
              <div className="btn-group" role="group">
                <button onClick={this._handleDecrementDate} className="btn btn-default"><i className="fa fa-arrow-left"></i></button>
                <button onClick={this._handleIncrementDate} className="btn btn-default"><i className="fa fa-arrow-right"></i></button>
              </div>
            </div>

          </div>
        </div>
        <div className="Scheduler__Grid">
          <div className="row row-no-gutter">
            <div className="col-sm-2 col-xs-4">
              <table className="table table-bordered">
                <thead>
                <tr>
                  <th>Instructors</th>
                </tr>
                </thead>
                <tbody>
                {this.state.instructors.map(this._renderInstructor)}
                </tbody>
              </table>
            </div>
            <div className="col-sm-10 col-xs-8">
              <div className="table-responsive">
                <table className="table table-bordered">
                  <thead>
                  <tr>
                    <th colSpan="3">8am</th>
                    <th colSpan="3">9am</th>
                    <th colSpan="3">10am</th>
                    <th colSpan="3">11am</th>
                    <th colSpan="3">12pm</th>
                    <th colSpan="3">1pm</th>
                    <th colSpan="3">2pm</th>
                    <th colSpan="3">3pm</th>
                    <th colSpan="3">4pm</th>
                    <th colSpan="3">5pm</th>
                    <th colSpan="3">6pm</th>
                    <th colSpan="3">7pm</th>
                  </tr>
                  </thead>
                  <tbody>
                  {this.state.instructors.map(this._renderInstructorSchedule)}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  },

  loadEvents: function() {
    this.loadCurrentUser();
    var dateFrom = moment(this.state.currentDate).format('YYYY-MM-DD');
    axios.get('/schedule/events.json?date_from=' + dateFrom + '&date_to=' + dateFrom)
      .then(function(response) {
        this.setState({ instructors: response.data.instructors });
      }.bind(this))
  },

  loadCurrentUser: function() {
    axios.get('/profile.json')
      .then(function(response) {
        if (typeof response.data === "string") {
          this.setState({currentUser: null});
        } else {
          this.setState({ currentUser: response.data });
        }
      }.bind(this))
  }
});