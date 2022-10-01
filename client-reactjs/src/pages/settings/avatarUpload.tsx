import React from 'react';
import api from '../../services/api';

type Props = {
  currentFile: File | null;
  progress: number;
  message: string;
  fileInfos: any;
  changeAvatarCallback: (avatar: string) => void;
};

type State = {
  currentFile: File | null;
  progress: number;
  message: string;
  fileInfos: any;
};

export default class AvatarUpload extends React.Component<Props, State> {
  constructor(props: any) {
    super(props);
    this.state = {
      currentFile: null,
      progress: 0,
      message: '',

      fileInfos: [],
    };

    this.selectFile = this.selectFile.bind(this);
  }

  selectFile(event: any) {
    this.setState({
      currentFile: event.target.files[0],
    });
  }

  onUploadProgress = (progressEvent: any) => {
    let percentCompleted = Math.round(
        (progressEvent.loaded * 100) / progressEvent.total
      ),
      progress = percentCompleted;
    this.setState({ progress });
  };

  upload() {
    let currentFile = this.state.currentFile;

    this.setState({
      progress: 0,
      currentFile: currentFile,
    });
    if (currentFile === null) {
      window.alert('Please select a file');
      return;
    }
    let formData = new FormData();
    formData.append('avatar', currentFile);

    api
      .put('avatar/upload', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        onUploadProgress: this.onUploadProgress,
      })
      .then((response) => {
        console.log(response.data);
        let newAvatarPath = response.data.data.avatar.generatedPath;
        this.props.changeAvatarCallback(newAvatarPath);

        this.setState({
          message: response.data.data.message,
        });
      });

    // UploadService.upload(currentFile, (event) => {
    //   this.setState({
    //     progress: Math.round((100 * event.loaded) / event.total),
    //   });
    // })
    //   .then((response) => {
    //     this.setState({
    //       message: response.data.message,
    //     });
    //     return UploadService.getFiles();
    //   })
    //   .then((files) => {
    //     this.setState({
    //       fileInfos: files.data,
    //     });
    //   })
    //   .catch(() => {
    //     this.setState({
    //       progress: 0,
    //       message: "Could not upload the file!",
    //       currentFile: undefined,
    //     });
    //   });

    this.setState({
      currentFile: null,
    });
  }

  componentDidMount() {
    // UploadService.getFiles().then((response) => {
    //   this.setState({
    //     fileInfos: response.data,
    //   });
    // });
  }

  render() {
    const { currentFile, progress, message, fileInfos } = this.state;

    return (
      <div>
        {currentFile && (
          <div className='progress'>
            <div
              className='progress-bar progress-bar-info progress-bar-striped'
              role='progressbar'
              aria-valuenow={progress}
              aria-valuemin={0}
              aria-valuemax={100}
              style={{ width: progress + '%' }}
            >
              {progress}%
            </div>
          </div>
        )}

        <label className='btn btn-default'>
          <input type='file' onChange={this.selectFile} />
        </label>

        <button
          className='btn btn-success'
          disabled={!currentFile}
          onClick={this.upload.bind(this)}
        >
          Upload
        </button>

        <div className='alert alert-light' role='alert'>
          {message}
        </div>

        {/* <div className='card'>
          <div className='card-header'>List of Files</div>
          <ul className='list-group list-group-flush'>
            {fileInfos &&
              fileInfos.map((file: any, index: number) => (
                <li className='list-group-item' key={index}>
                  <a href={file.url}>{file.name}</a>
                </li>
              ))}
          </ul>
        </div> */}
      </div>
    );
  }
}
