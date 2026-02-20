import './src/style.css'
import { Elm } from './src/Main.elm'
import planningData from './src/planning.json'
import benevolesData from './src/benevoles.json'

const savedMissions = JSON.parse(localStorage.getItem('selectedMissions') || '[]')
const savedTeams = JSON.parse(localStorage.getItem('selectedTeams') || '[]')

const app = Elm.Main.init({
    node: document.getElementById('app'),
    flags: {
        planningData: planningData,
        benevolesData: benevolesData,
        selectedMissions: savedMissions,
        selectedTeams: savedTeams
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

if (app.ports.saveTeamsSelection) {
    app.ports.saveTeamsSelection.subscribe(function (selection) {
        localStorage.setItem('selectedTeams', JSON.stringify(selection))
    })
}

if (app.ports.exportCalendar) {
    app.ports.exportCalendar.subscribe(function (events) {
        const content = generateICS(events);
        if (content) {
            downloadICS(content, events.length === 1 ? `${events[0].title.replace(/\s+/g, '_')}.ics` : `Mon_Planning_Benevole.ics`);
        }
    });
}

function generateICS(events) {
    if (!events || events.length === 0) return null;

    const lines = [
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'PRODID:-//Coupe de France//Nantes 2026//FR',
        'CALSCALE:GREGORIAN'
    ];

    events.forEach(event => {
        lines.push('BEGIN:VEVENT');

        const title = event.title;
        const description = event.description || '';
        const location = event.location || '';

        if (event.day && event.startTime && event.endTime) {
            // Timed event
            const date = event.day.replace(/-/g, '');
            const dtStart = date + 'T' + event.startTime.replace(':', '') + '00';
            const dtEnd = date + 'T' + event.endTime.replace(':', '') + '00';
            lines.push(`DTSTART:${dtStart}`);
            lines.push(`DTEND:${dtEnd}`);
        } else if (event.day) {
            // All day event
            const date = event.day.replace(/-/g, '');
            const dtStart = date;
            const nextDayDate = new Date(event.day);
            nextDayDate.setDate(nextDayDate.getDate() + 1);
            const dtEnd = nextDayDate.toISOString().split('T')[0].replace(/-/g, '');
            lines.push(`DTSTART;VALUE=DATE:${dtStart}`);
            lines.push(`DTEND;VALUE=DATE:${dtEnd}`);
        } else {
            // US10: Event without day (AMONT). 
            // We use a fixed day for the "Amont" part (e.g. April 2nd) or just skip if we want to be safe.
            // But the US says "export as whole day event".
            // Let's use 2026-04-02 for AMONT if possible.
            const amontDay = '20260402';
            lines.push(`DTSTART;VALUE=DATE:${amontDay}`);
            lines.push(`DTEND;VALUE=DATE:20260403`);
        }

        lines.push(`SUMMARY:${title}`);
        lines.push(`DESCRIPTION:${description}`);
        lines.push(`LOCATION:${location}`);
        lines.push('END:VEVENT');
    });

    lines.push('END:VCALENDAR');

    return lines.join('\r\n');
}

function downloadICS(content, filename) {
    const blob = new Blob([content], { type: 'text/calendar;charset=utf-8' });
    const link = document.createElement('a');
    link.href = window.URL.createObjectURL(blob);
    link.setAttribute('download', filename);
    link.click();
}
