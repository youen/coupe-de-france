import './src/style.css'
import { Elm } from './src/Main.elm'
import planningData from './src/planning.json'
import benevolesData from './src/benevoles.json'

const savedMissions = JSON.parse(localStorage.getItem('selectedMissions') || '[]')

const app = Elm.Main.init({
    node: document.getElementById('app'),
    flags: {
        planningData: planningData,
        benevolesData: benevolesData,
        selectedMissions: savedMissions
    }
})

app.ports.print.subscribe(function () {
    window.print();
});

if (app.ports.saveBenevoleSelection) {
    app.ports.saveBenevoleSelection.subscribe(function (selection) {
        localStorage.setItem('selectedMissions', JSON.stringify(selection))
    })
}
