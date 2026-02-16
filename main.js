import './src/style.css'
import { Elm } from './src/Main.elm'
import planningData from './src/planning.json'

const app = Elm.Main.init({
    node: document.getElementById('app'),
    flags: planningData
})

app.ports.print.subscribe(function () {
    window.print();
});
