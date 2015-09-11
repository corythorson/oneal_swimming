/** @jsx React.DOM */

var React = require('react');
var axios = require('axios');
var moment = require('moment');

var AssignTimeSlot = module.exports = React.createClass({
  propTypes: {
    timeSlot: React.PropTypes.object.isRequired,
    currentUser: React.PropTypes.object.isRequired
  },

  getInitialState: function() {
    return {
      status: 'form',
      errorMessage: null
    }
  },

  _assignedStudentToTimeSlot: function(student) {
    this.setState({ status: 'pending' });

    axios.post('/schedule/assign.json', { time_slot_id: this.props.timeSlot.id, student_id: student.id })
      .then(function(response) {
        if (response.data.error === null) {
          this.setState({
            errorMessage: null,
            status: 'completed'
          }, this.props.loadEvents());
        } else {
          this.setState({
            errorMessage: response.data.error,
            status: 'error'
          });
        }
      }.bind(this));
  },

  _renderStudentButton: function(student) {
    return (
      <div className="StudentButton">
        <button onClick={this._assignedStudentToTimeSlot.bind(this, student)} className="btn btn-primary btn-lg btn-block">
          {student.first_name}
        </button>
      </div>
    )
  },

  dateStr: function() {
    return moment(this.props.timeSlot.start).format('ddd, MMM D YYYY, h:mm a');
  },

  _renderForm: function() {
    if (this.props.currentUser) {
      if (this.props.currentUser.remaining_lessons > 0) {
        return (
          <div>
            <h4 className="text-center">You have {this.props.currentUser.remaining_lessons} lessons remaining</h4>

            <p className="text-center">Click on the student you would like to assign to this time slot</p>

            <div className="alert alert-warning text-center" role="alert">{this.dateStr()}</div>

            <div className="StudentButtonContainer">
              {this.props.currentUser.students.map(this._renderStudentButton)}
            </div>
            <button onClick={this.props.closeModal} className="btn btn-link btn-block">cancel</button>
          </div>
        );
      } else {
        return (
          <div>
            <h4 className="text-center">You have {this.props.currentUser.remaining_lessons} lessons remaining</h4>
            <p className="text-center">You need to purchase more time slots if you would like to assign more lessons.</p>
            <a href="/our_lessons" className="btn btn-warning btn-lg btn-block">Buy More Lessons</a>
          </div>
        );
      }
    } else {
      return (
        <div>
          <h4 className="text-center">You must be logged in</h4>

          <div className="text-center">
            <a href="/users/sign_in" className="btn btn-lg btn-primary">Log In</a>
          </div>
        </div>
      );
    }
  },

  _renderPending: function() {
    return (
      <div>
        <h4 className="text-center">Saving...</h4>
      </div>
    )
  },

  _renderError: function() {
    return (
      <div>
        <h4 className="text-center">Error: {this.state.errorMessage}</h4>
      </div>
    )
  },

  _renderCompleted: function() {
    return (
      <div>
        <h4 className="text-center">Done!</h4>
      </div>
    )
  },

  render: function() {
    if (this.state.status === 'form') {
      return this._renderForm();
    } else if (this.state.status == 'pending') {
      return this._renderPending();
    } else if (this.state.status == 'error') {
      return this._renderError();
    } else if (this.state.status == 'completed') {
      return this._renderCompleted();
    }
  }
});