var o_delay = {
    "min": 1,
    "max": 3000,
    "weight": 25,
    "increased_weight_min": 10,
    "increased_weight_max": 25,
    "repeate_weight": 25,
    "expected_probablity": 1,
    "trueup_percent": 5
};

var o_drop = {
    "weight": 20,
    "increased_weight_min": 25,
    "increased_weight_max": 50,
    "repeate_weight": 15,
    "expected_probablity": 1,
    "trueup_percent": 5
};

var o_error = {
    "codes": {400:1,401:1,403:1,404:1,405:1,429:1,500:1,502:1,503:1,504:1},
    "weight": 20,
    "increased_weight_min": 30,
    "increased_weight_max": 70,
    "repeate_weight": 15,
    "expected_probablity": 1,
    "trueup_percent": 5
};

var o_valid = {
    "weight": 70
}

function weightedSearch(obj) {
    var weights = Object.values(obj).reduce(function(a, b) { return a + b; }, 0);
    var random = Math.floor(Math.random() * weights)
    for (var i = 0; i < Object.keys(obj).length; i++){
        random -= Object.values(obj)[i];
        if (random < 0) {
            return Object.keys(obj)[i];
        }
    }
}

function mathRange(min,max){
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min)) + min;
}

function praseHeader(data){
    var o_data = data.split('\r\n');
    var a_data_1 = o_data[0].split(' ');
    var request = {}
    request.method = a_data_1[0];
    request.url = a_data_1[1];
    request.version = a_data_1[2];
    request.headers = {};
    for (var i=1;i<o_data.indexOf('');i++) {
        var header = o_data[i].split(':');
        request.headers[header[0]] = header[1];
    }

    return request;
}

function delayHandler(delayed,obj){
    if (delayed == "true") {
        var timer = mathRange(o_delay.min,o_delay.max);
        setTimeout(
            function(){
                obj;
            },
            timer
        );
    } else {
        obj;
    }
}

function delayCheck(s) {
    s.on('upload', function (data, flags) {
        var n = data.indexOf('\n');
        if (n != -1) {
            if (s.variables.lastDelay == "true"){
                o_delay.weight += mathRange(o_delay.increased_weight_min,o_delay.increased_weight_max);
            }

            var delayed = weightedSearch({true:o_delay.weight,false:100-o_delay.weight});
            delayHandler(delayed,s.done());
        }
    })
}

function streamStart(s){
    s.on('upload', function (data, flags) {
        if (!flags.last) {
            var request = praseHeader(data);
            var currentRequest = request.headers.Host+request.url;
            var lastRequest = s.variables.lastRequest;
            var o_request = {};

            //s.log(JSON.stringify({true:o_delay.weight,false:100-o_delay.weight}));
            switch(s.variables.lastAction) {
                case "drop":
                    o_drop.weight += mathRange(o_drop.increased_weight_min,o_drop.increased_weight_max);
                    if (currentRequest === lastRequest) o_drop.weight += o_drop.repeate_weight;
                    break;
                case "error":
                    o_error.weight += mathRange(o_error.increased_weight_min,o_error.increased_weight_max);
                    if (currentRequest === lastRequest) o_error.weight += o_error.repeate_weight;
                    break;
                default:
            }

            o_request = {
                "drop": o_drop.weight,
                "error": o_error.weight,
                "valid": o_valid.weight
            }

            o_request.result = weightedSearch(o_request);

            s.variables.lastRequest = currentRequest;
            s.log(JSON.stringify(o_request));
            switch (o_request.result) {
                case "drop":
                    s.variables.lastDrop = currentRequest;
                    s.variables.lastAction = "drop";
                    s.deny();
                    s.off('upload');
                    break;
                case "error":
                    s.variables.lastError = currentRequest;
                    s.variables.lastAction = "error";
                    if (s.variables.lastErrorCode) o_error.codes[s.variables.lastErrorCode] = Object.keys(o_error.codes).length;
                    s.variables.lastErrorCode = weightedSearch(o_error.codes)

                    s.send("GET /error/" + s.variables.lastErrorCode + " HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n");
                    s.off('upload');
                    break;
                default:
                    s.send(data)
                    s.off('upload');
                    s.variables.lastAction = "valid";
            }
        }
    });
}
