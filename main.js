import './src/style.css'
import { Elm } from './src/Main.elm'
import planningData from './src/planning.json'
import benevolesData from './src/benevoles.json'

const app = Elm.Main.init({
    node: document.getElementById('app'),
    flags: {
        planningData: planningData,
        benevolesData: benevolesData
    }
})

app.ports.print.subscribe(function () {
    window.print();
});
