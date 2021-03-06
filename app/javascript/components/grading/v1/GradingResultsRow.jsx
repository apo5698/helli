import React from 'react';
import Badge from '../../templates/Badge';

class GradingResultsRow extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      gradeItem: props.gradeItem,
    };

    this.studentCell = this.studentCell.bind(this);
    this.fileCell = this.fileCell.bind(this);
    this.statusCell = this.statusCell.bind(this);
    this.gradeCell = this.gradeCell.bind(this);
    this.outputCell = this.outputCell.bind(this);
    this.feedbackCell = this.feedbackCell.bind(this);
    this.actionCell = this.actionCell.bind(this);

    this.run = this.run.bind(this);
  }

  run(options) {
    const { gradeItem: { path } } = this.state;
    const { incrementCount } = this.props;

    console.log(JSON.stringify({ options: options }));
    fetch(path + '/run', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ options: options }),
    })
      .then(r => {return r.json();})
      .then(r => {
        this.setState({
          gradeItem: r,
        });
        incrementCount();
      });
  }

  studentCell(gradeItem) {
    return (
      <td style={{ maxWidth: '100px' }}>{gradeItem.participant.name}</td>
    );
  }

  fileCell(gradeItem) {
    const { rubricItem: { filename } } = this.props;

    return (
      <td>
        {filename ?
          <a href={gradeItem.path} data-remote='true'
             data-toggle='modal' data-params='view=file'>{filename}</a> :
          ''}
      </td>
    );
  }

  statusCell(gradeItem) {
    return (
      <td>
        <Badge type={gradeItem.status}>{gradeItem.statusInText}</Badge>
        <span> </span>
        {
          gradeItem.status === 'error'
            ? <Badge type={gradeItem.status}>{gradeItem.error}</Badge>
            : ''
        }
      </td>
    );
  }

  gradeCell(gradeItem) {
    const { rubricItem: { maxPoint } } = this.props;

    return (
      <td>
        {gradeItem.point || '?'}/{maxPoint}
      </td>
    );
  }

  outputCell(gradeItem) {
    let stdout = gradeItem.stdout;
    let stderr = gradeItem.stderr;
    if (stdout || stderr) {
      let previewText = stderr ? stderr : stdout;
      let title = previewText.length > 200 ? 'Output is too long. Click to view.' : previewText;
      return (
        <td>
          <span data-toggle="tooltip" title={title}>
            <a
              href={gradeItem.path}
              data-remote="true"
              data-toggle="modal"
              data-params="view=output"
            >
              View
            </a>
          </span>
        </td>
      );
    } else {
      return (
        <td></td>
      );
    }
  }

  feedbackCell(gradeItem) {
    return (
      <td
        style={{ maxWidth: '250px' }}
      >
        {gradeItem.feedback}
      </td>
    );
  }

  actionCell(gradeItem) {
    return (
      <td>
        <a
          href={gradeItem.path}
          data-remote="true"
          data-toggle="modal"
          data-params="view=edit"
        >
          Edit
        </a>
      </td>
    );
  }

  render() {
    let gradeItem = this.state.gradeItem;
    let trColor = ['success', 'inactive'].includes(gradeItem.status) ? '' : 'table-danger';
    return (
      <tr className={trColor} id={`autograding-item-${gradeItem.id}`}>
        {this.studentCell(gradeItem)}
        {this.fileCell(gradeItem)}
        {this.statusCell(gradeItem)}
        {this.gradeCell(gradeItem)}
        {this.outputCell(gradeItem)}
        {this.feedbackCell(gradeItem)}
        {this.actionCell(gradeItem)}
      </tr>
    );
  }
}

export default GradingResultsRow;
