// --------------------------------------------------------
    // Pull in the libraries
    // --------------------------------------------------------
    const app = require('express')()
    const bodyParser = require('body-parser')
    const config = require('./node_modules/pusher/lib/config.js')
    const Pusher = require('pusher')
    const pusher = new Pusher({
        appId: '752571',
        key: '222656ee218225affb85',
        secret: '2277d462552b168f73aa',
        cluster: 'us2',
        encrypted: true
    })
    // --------------------------------------------------------
    // In-memory database
    // --------------------------------------------------------
    let rider = null
    let driver = null
    let user_id = null
    let status = "Neutral"
    let origin = ""
    let destination = ""
    // --------------------------------------------------------
    // Express Middlewares
    // --------------------------------------------------------
    app.use(bodyParser.json())
    app.use(bodyParser.urlencoded({extended: false}))
    // --------------------------------------------------------
    // Helpers
    // --------------------------------------------------------
    function uuidv4() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }
    // --------------------------------------------------------
    // Routes
    // --------------------------------------------------------
    // ----- Rider --------------------------------------------
    app.get('/status', (req, res) => res.json({ status }))
    app.get('/request', (req, res) => res.json(driver))
    app.post('/request', (req, res) => {
        user_id = req.body.user_id
        status = "Searching"
        destination = req.body.latitude + ',' + req.body.longitude
        rider = { name: "CantHold", longitude: parseFloat(req.body.longitude), latitude: parseFloat(req.body.latitude) }
        pusher.trigger('cabs', 'status-update', { status, rider })
        res.json({ status: true })
    })
    app.delete('/request', (req, res) => {
        driver = null
        status = "Neutral"
        pusher.trigger('cabs', 'status-update', { status })
        res.json({ status: true })
    })
    // ----- Driver ------------------------------------------
    app.get('/pending-rider', (req, res) => res.json(rider))
    app.post('/status', (req, res) => {
        status = req.body.status
        if (status == "EndedTrip" || status == "Neutral") {
            rider = driver = null
        } else {
            origin = req.body.latitude + ',' + req.body.longitude
            var eta = ''
            var spawn = require("child_process").spawn;
            var pythonprocess = spawn('python',['ETA.py', origin, destination] );
            pythonprocess.stdout.on('data', function(data) { 
        eta = data.toString();
    } )
            pythonprocess.on('end', function(){
                console.log(eta)
            })

            console.log(eta)
            console.log(origin)
            console.log(destination)
            driver = { name: "PlzHold", ETA: eta }
        }
        pusher.trigger('cabs', 'status-update', { status, driver })
        res.json({ status: true })
    })
    // ----- Misc ---------------------------------------------
    app.get('/', (req, res) => res.json({ status: "success" }))
    // --------------------------------------------------------
    // Serve application
    // --------------------------------------------------------
    app.listen(4000, _ => console.log('App listening on port 4000!'))