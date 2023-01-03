$.ajax({
    url: "/api/v1/category",
    type: "GET",
    contentType: "application/json; charset=utf-8"
  }).then(function (response) {
    var dataToReturn = [];
    // 2
    for (var i=0; i < response.length; i++) {
      var tagToTransform = response[i];
      var newTag = {
                     id: tagToTransform["name"],
                     text: tagToTransform["name"]
                   };
      dataToReturn.push(newTag);
    }
    // 3
    $("#categories").select2({
      // 4
      placeholder: "Select Categories for the Acronym",
      // 5
      tags: true,
      // 6
      tokenSeparators: [','],
      // 7
      data: dataToReturn
    });
  });