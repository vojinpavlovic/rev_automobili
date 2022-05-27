

var currentIndex = 0
var vehicles = null
var resourceName = 'rev_automobili'


window.addEventListener('message', function(event)
{ 
    var item = event.data;
    switch(item.action) {
        case('shop'):
            vehicles = item.shopList
            createShop()
            $("#shop-container").show()
            return
        case('garage'):
            $("#garage-container").show()
            createGarageList(item.garage, item.vehicles)
        default:
            return;
    }
});

function close() {
    clearShop()
    $("#garage-container").hide()
    currentIndex = 0
    $.post('http://' + resourceName + '/close', JSON.stringify({}))
}


function createShop() {
    if (!vehicles) { 
        close()
        return
    }

    if (vehicles[currentIndex] == 'none') {
        return;
    }
    if (typeof vehicles[currentIndex - 1] === 'undefined') {
        vehicles[currentIndex - 1] = 'none'
    }
    if (typeof vehicles[currentIndex + 1] === 'undefined') {
        vehicles[currentIndex + 1] = 'none'
    }

    createShopHeader()

    $("#content-container").append(`
        <div class="col-2">
            <div class="btn-wrapper">    
                <a class="circle-btn" id="prev-btn" href="#">
                    <img id="left-image" src="`+ (vehicles[currentIndex - 1] == 'none' ? 'https://kknd26.ru/images/no_photo.png' : vehicles[currentIndex - 1].image) +`">
                </a>
            </div>
        </div>

        <div class="col-8">
            <div class="col-12">
                <h4 class="text-center">`+ vehicles[currentIndex].brand +`</h4><h1 class="text-center">`+ vehicles[currentIndex].name +`</h1>
            </div>
            <div class="col-12 pic-container">
                <img id="center-image" src="`+ vehicles[currentIndex].image +`" class="mx-auto">
            </div>
            <div class="col-12">
                ` + ((vehicles[currentIndex].stock > 0) ? '<h2 class="text-center">IMA</h2><p class="text-center gray">NA STANJU</p>' : '<h2 class="text-center">NEMA</h2><p class="text-center gray">NA STANJU</p>') + `
            </div>
        </div>

        <div class="col-2">
            <div class="btn-wrapper">
                <a class="circle-btn-right" id="next-btn" href="#">
                    <img id="right-image" src="`+ (vehicles[currentIndex + 1] == 'none' ? 'https://kknd26.ru/images/no_photo.png' : vehicles[currentIndex + 1].image) +`">
                </a>
            </div>
        </div>
    `);

    $("#next-btn").click(function(){
        if (vehicles[currentIndex + 1] != 'none') {
            currentIndex ++;
            $("#footer-container").html('')
            $("#content-container").html('')
            createShop()
            return;
        }
    })
    $("#prev-btn").click(function(){
        if (vehicles[currentIndex - 1] != 'none') {
            if (currentIndex > 0) currentIndex --;
            $("#footer-container").html('')
            $("#content-container").html('')
            createShop()
            return;
        }
    })

    $("#footer-container").append(`
        <div class="col-6">
            <p class="mx-4 price gray">CENA <span>`+ vehicles[currentIndex].price +`$</span></p>
        </div>
        <div class="col-6">
            <button class="panama-btn btn-blue mx-4" id="buy`+ currentIndex +`">Kupi vozilo</button>
            <button class="panama-btn btn-white" id="test`+ currentIndex+`">Test vozilo</button>
        </div>
    `);
    $("#test" + currentIndex).click(function() {
        $.post('http://' + resourceName + '/testvehicle', JSON.stringify({
            model : vehicles[currentIndex].model, vehicleType : 'car'
        }))
        close();
    });
    $("#buy" + currentIndex).click(function() {
        $.post('http://' + resourceName + '/buyvehicle', JSON.stringify({
            model : vehicles[currentIndex].model, image : vehicles[currentIndex].image, name : vehicles[currentIndex].name, brand : vehicles[currentIndex].brand
        }))
        close();
    });
}

$(document).ready(function () {
    $("body").on("keyup", function(key) {
        closeBtn = [27];
        if (closeBtn.includes(key.which)) {
           close();
        }
    });
});

function createShopHeader() {
    $("#header-container").html('')
    $("#header-container").append(`
        <div class="col-4">
            <img src="img/Logo.png" style="width: 120px; height: auto;" class="mx-4">
        </div>
        <div class="col-8">
            <a href="#" class="float-right mx-4 my-2 no-text-decoration white" id="listVehicles"><span class="gray">Lista svih vozila <i class="gray fas fa-chevron-circle-down"></i></span></a>
        </div>
    `);
    $("#listVehicles").click(function() {
        createShopList()  
    });
}


function createShopList() {
    $("#header-container").html('')
    $("#content-container").html('')
    $("#footer-container").html('')
    $("#third-window").html('')
    $("#third-window").append(`
        <div class="row">
            <div class="col-12"><i class="right my-2 fas fa-times-circle" id="close-btn"></i></div>
        </div>
        <p class="text-center gray my-5">Vrsta vozila</p>
        <div class="container" id="list-container"></div>
    `);
    $.each(vehicles, function(k,v) {
        if (typeof v.image !== 'undefined') {
            $("#list-container").append(`
                <div class="row">
                    <div class="col-12 list-card">
                        <div class="row">
                            <div class="col-2 pic-slot d-flex align-items-center"><img class="mx-2" src="`+ v.image +`" style="width: 100%;"></div>
                            <div class="col-2 d-flex align-items-center"><span class="">`+ v.brand + " " + v.name +`</span></div>
                            <div class="col-6 d-flex align-items-center"><span>`+ v.price +`$</span></div>
                            <div class="col-1 eye d-flex align-items-center"><i id="btn-`+ k +`" class="fas fa-eye eye-right"></i></div>
                        </div>
                    </div>
                </div>
            `);
            $("#btn-" + k).click(function() {
                $("#third-window").html('');
                currentIndex = k
                createShop()
            });
        }
    });
    $("#close-btn").click(function() {
        $("#third-window").html('')
        createShop()
    })
}

function clearShop() {
    vehicles = null
    $("#shop-container").hide()
    $("#content-container").html('')
    $("#header-container").html('')
    $("#footer-container").html('')
    $("#third-window").html('')
}


function createGarageList(garage, vehicles) {
    let counter = 0
    $("#garage-list-container").html('')
    $("#garage-container").html('')
    $("#garage-container").append(`
        `+ (garage == 'pauk' ? '<p class="text-center gray my-5">Garaza:' + garage.toUpperCase() + " Cena 2000" : '<p class="text-center gray my-5" style="margin:0 !important;margin-top:12px !important;">Garaza: '+ garage.toUpperCase() +'</p>') +`
        <div class="container" id="garage-list-container"></div>
    `);

    $.each(vehicles, function(k,v) {
        if (garage == v.garage) {
            counter ++;
            let props = JSON.parse(v.props)
            let body = Math.floor(props.bodyHealth)
            let engine = Math.floor(props.engineHealth)
            let fuel = props.fuelLevel
            let description = JSON.parse(v.description)

            let stats = []

            if (body == 1000) stats[0] = 'Nije osteceno (' + body + ')'
            else if (body >= 700) stats[0] = 'Malo osteceno (' + body + ')'
            else if (body >= 400) stats[0] = 'Vece ostecenje (' + body + ')'
            else stats[0] = 'Jako osteceno (' + body + ')' 

            if (engine == 1000) stats[1] = 'Nije osteceno (' + engine + ')'
            else if (engine >= 700) stats[1] = 'Malo osteceno (' + engine + ')'
            else if (engine >= 400) stats[1] = 'Vece ostecenje (' + engine + ')'
            else stats[1] = 'Jako osteceno (' + engine + ')'

            let damageString = `
                <br> <i class="fas fa-gas-pump red" style="font-size:150%;"></i> Gorivo: `+ fuel +`%  ` + `<br>
                <i class="fas fa-car-crash red" style="font-size:150%;"></i> Karoserija: `+ stats[0] +` <br> 
                <i class="fas fa-car-battery red" style="font-size:150%;"></i> Motor: `+ stats[1] +`               
            `
            let takeVehBtn = '<button class="list-btn" id="takeout-'+ k +'">Izvadi vozilo</button>'
            if (v.stored == 0) {
                takeVehBtn = '<button class="list-btn" style="background: none;" id="takeout-`+ k +`">Vozilo je vani</button>'
            }


            $("#garage-list-container").append(`
                <div class="row">
                    <div class="col-12 list-card my-2">
                        <div class="row">
                            <div class="col-2 pic-slot d-flex align-items-center"><img class="mx-2" src="`+ description.img +`" style="width: 100%;"></div>
                            <div class="col-2 d-flex align-items-center"><span>`+ description.brand + " " + description.name + " " + '<br><i class="fas fa-warehouse garage-smx2-font gray"></i> <span class="garage-smx2-font gray">' + v.garage.toUpperCase() +'</span>' + `</span></div>
                            <div class="col-4 d-flex align-items-center">
                                <span class="garage-sm-font">Tablice: `+ props.plate +` ` + '<span class="garage-smx1-font gray">' + damageString + '</span>' + `</span>
                            </div>
                            <div class="col-3 eye">
                                `+ takeVehBtn +`
                            </div>
                        </div>
                    </div>
                </div>
            `); 

            $("#takeout-" + k).click(function() {
                if (v.stored == 1) {
                    $.post('http://' + resourceName + '/takeVehicleOut', JSON.stringify({
                        plate : k, props : props, engineHP : v.engineHP, fuel : v.fuel, body: v.body, garage : v.garage
                    }))
                    close()
                }
            })
        }
    })

    if (counter == 0) {  
        if (garage != 'pauk') {
            $("#garage-container").append(`
                <div class="col-12 list-card my-2">
                    <h1 class="text-center">Nemate nijedno vozilo u ovoj garazi</h1>
                </div>
            `);
        } else {
            $("#garage-container").append(`
                <div class="col-12 list-card my-2">
                    <h1 class="text-center">Nemate nijedno vozilo na parking servisu</h1>
                </div>
            `);
        }
    }
}