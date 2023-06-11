// app/assets/javascripts/file_uploads.js

$(document).ready(function() {
  $('#upload-form').submit(function(e) {
    e.preventDefault();

    var files = $('#file-input')[0].files;

    // Disable the form and upload button
    $('#file-input').prop('disabled', true);
    $('#upload-button').prop('disabled', true);

    // Create a progress bar for each file
    for (var i = 0; i < files.length; i++) {
      var progressBar = $('<div class="progress-bar"></div>');
      progressBar.append($('<div class="progress"></div>'));
      $('#progress-container').append(progressBar);
    }

    // Upload each file using AJAX
    var uploadedFileCount = 0;

    for (var i = 0; i < files.length; i++) {
      var file = files[i];
      var formData = new FormData();
      formData.append('file', file);

      $.ajax({
        url: '/file_uploads',
        type: 'POST',
        data: formData,
        processData: false,
        contentType: false,
        xhr: function() {
          var xhr = new window.XMLHttpRequest();
          xhr.upload.addEventListener('progress', function(e) {
            if (e.lengthComputable) {
              var percent = Math.round((e.loaded / e.total) * 100);
              $('.progress-bar').eq(i).find('.progress').css('width', percent + '%');
            }
          }, false);
          return xhr;
        },
        success: function(data) {
          uploadedFileCount++;
          if (uploadedFileCount === files.length) {
            // All files uploaded successfully
            $('#file-input').prop('disabled', false);
            $('#upload-button').prop('disabled', false);
            $('.progress-bar').remove();
            console.log('All files uploaded!');
            console.log(data); // Array of uploaded file keys
          }
        },
        error: function(xhr, status, error) {
          console.error('File upload error:', error);
        }
      });
    }
  });
});
