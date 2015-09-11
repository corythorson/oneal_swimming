/** @jsx React.DOM */

var React = require('react');
var Tooltip = require('react-bootstrap').Tooltip;
var OverlayTrigger = require('react-bootstrap').OverlayTrigger;
var _ = require('lodash');

var AssignTimeSlot = require('./assign-time-slot');
var TimeSlotDetails = require('./time-slot-details');
var Modal = require('react-modal');
var appElement = document.getElementById('scheduler-app');
Modal.setAppElement(appElement);
Modal.injectCSS();

var ScheduleCell = module.exports = React.createClass({
  propTypes: {
    timeSlot: React.PropTypes.object,
    currentUser: React.PropTypes.object.isRequired,
    loadEvents: React.PropTypes.func.isRequired
  },

  getInitialState: function() {
    return {
      modalIsOpen: false
    }
  },

  openModal: function() {
    this.setState({modalIsOpen: true});
  },

  closeModal: function() {
    this.setState({modalIsOpen: false});
  },

  render: function() {
    if ((this.props.timeSlot !== undefined) && (this.props.timeSlot !== null)) {
      var student = this.props.timeSlot.student;
      if (student !== null) {
        var studentIds = [];
        if (this.props.currentUser !== null) {
          studentIds = _.pluck(this.props.currentUser.students, 'id');
        }
        if (_.includes(studentIds, student.id)) {
          return (
            <td className="TimeSlot TimeSlot--MyStudent TimeSlot--Unavailable">
              <a onClick={this.openModal}>{student.first_name}<br/>{student.last_name}</a>
              <Modal
                className="Modal__Bootstrap modal-dialog"
                closeTimeoutMS={150}
                isOpen={this.state.modalIsOpen}
                onRequestClose={this.closeModal}
                >
                <div className="modal-content">
                  <div className="modal-header">
                    <button type="button" className="close" onClick={this.closeModal}>
                      <span aria-hidden="true">&times;</span>
                      <span className="sr-only">Close</span>
                    </button>
                    <h4 className="modal-title">Assign Time Slot</h4>
                  </div>
                  <div className="modal-body">
                    <TimeSlotDetails loadEvents={this.props.loadEvents} closeModal={this.closeModal} timeSlot={this.props.timeSlot} currentUser={this.props.currentUser} />
                  </div>
                </div>
              </Modal>
            </td>
          );
        } else {
          return (
            <td className="TimeSlot TimeSlot--Unavailable">
              <a>{student.first_name}<br/>{student.last_name}</a>
            </td>
          );
        }
      } else {
        return (
          <td className="TimeSlot TimeSlot--Available">
            <a onClick={this.openModal}></a>
            <Modal
              className="Modal__Bootstrap modal-dialog"
              closeTimeoutMS={150}
              isOpen={this.state.modalIsOpen}
              onRequestClose={this.closeModal}
              >
              <div className="modal-content">
                <div className="modal-header">
                  <button type="button" className="close" onClick={this.closeModal}>
                    <span aria-hidden="true">&times;</span>
                    <span className="sr-only">Close</span>
                  </button>
                  <h4 className="modal-title">Assign Time Slot</h4>
                </div>
                <div className="modal-body">
                  <AssignTimeSlot loadEvents={this.props.loadEvents} closeModal={this.closeModal} timeSlot={this.props.timeSlot} currentUser={this.props.currentUser} />
                </div>
              </div>
            </Modal>
          </td>
        );
      }
    } else {
      return <td className="TimeSlot TimeSlot--Empty"><a></a></td>;
    }
  }
});