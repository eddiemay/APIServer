var gpios = {};
function redraw() {
  var innerHTML = '';
  for (var id in gpios) {
    var gpio = gpios[id];
    innerHTML += '<tr><td><button onclick="remove(' + gpio.id + ')">Remove</button></td>'
        + '<td>' + gpio.id + '</td>'
        + '<td><input type="text" value="' + gpio.name + '"></td>'
        + '<td>' + gpio.mode + '</td>'
        + '<td>' + gpio.value + '</td>';
    if (gpio.mode == "OUTPUT") {
      innerHTML += '<td><button onclick="update(' + gpio.id + ', \'value\', \'LOW\')">Set Low</button>'
          + '<button onclick="update(' + gpio.id + ', \'value\', \'HIGH\')">Set High</button></td></tr>';
    } else {
      innerHTML += '<td><button onclick="get(' + gpio.id + ')">Read Value</button>';
    }
  }
  document.getElementById('gpios').innerHTML = innerHTML;
}
function create() {
  var newGPIO = {
    id: parseInt(document.getElementById("pin").value, 10),
    name: document.getElementById("name").value,
    mode: document.getElementById("mode").value
  };
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      newGPIO = JSON.parse(xmlHttp.response);
      gpios[newGPIO.id] = newGPIO;
      redraw();
    }
  };
  xmlHttp.open('PUT', '/api/gpios/' + newGPIO.id, true);
  xmlHttp.send(JSON.stringify({entity: newGPIO}));
}
function get(id) {
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      gpios[id] = JSON.parse(xmlHttp.response);
      redraw();
    }
  };
  xmlHttp.open('GET', '/api/gpios/' + id, true);
  xmlHttp.send(null);
}
function refresh() {
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      var response = JSON.parse(xmlHttp.response);
      gpios = {};
      for (var i = 0; i < response.result.length; i++) {
        var gpio = response.result[i];
        gpios[gpio.id] = gpio;
      }
      redraw();
    }
  };
  xmlHttp.open('GET', '/api/gpios', true);
  xmlHttp.send(null);
}
function update(id, property, value) {
  var updateRequest = {
    entity: {},
    updateMask: [property]
  };
  updateRequest.entity[property] = value;
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      gpios[id] = JSON.parse(xmlHttp.response);
      redraw();
    }
  };
  xmlHttp.open('PATCH', '/api/gpios/' + id, true);
  xmlHttp.send(JSON.stringify(updateRequest));
}
function remove(id) {
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function() {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      delete gpios[id];
      redraw();
    }
  };
  xmlHttp.open('DELETE', '/api/gpios/' + id, true);
  xmlHttp.send(null);
}
refresh();