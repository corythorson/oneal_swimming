/** @jsx React.DOM */

var React = require('react');
var axios = require('axios');
var moment = require('moment');

var TimeSlotDetails = module.exports = React.createClass({
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

  _unassignStudentFromTimeSlot: function() {
    this.setState({ status: 'pending' });

    axios.post('/schedule/unassign.json', { time_slot_id: this.props.timeSlot.id })
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

  dateStr: function() {
    return moment(this.props.timeSlot.start).format('ddd, MMM D YYYY, h:mm a');
  },

  _renderForm: function() {
    return (
      <div>
        <h4 className="text-center">You have {this.props.currentUser.remaining_lessons} lessons remaining</h4>

        <p className="text-center">The following time slot is assigned to <strong>{this.props.timeSlot.student.first_name}</strong></p>
        <div className="alert alert-warning text-center" role="alert">{this.dateStr()}</div>

        <div className="StudentButtonContainer">
          <button onClick={this._unassignStudentFromTimeSlot} className="btn btn-lg btn-danger btn-block">Unassign {this.props.timeSlot.student.first_name} from this time slot</button>
        </div>
        <button onClick={this.props.closeModal} className="btn btn-link btn-block">cancel</button>
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

  _renderError: function() {
    return (
      <div>
        <h4 className="text-center">Error: {this.state.errorMessage}</h4>
      </div>
    )
  },

  render: function() {
    if (this.state.status === 'form') {
      return this._renderForm();
    } else if (this.state.status === 'error') {
      return this._renderError();
    } else if (this.state.status === 'completed') {
      return this._renderCompleted();
    }
  }
});