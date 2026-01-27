import React from 'react';
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js';
import { Doughnut } from 'react-chartjs-2';

ChartJS.register(ArcElement, Tooltip, Legend);

interface Props {
    summary: {
        malicious: number;
        suspicious: number;
        harmless: number;
    };
}

export const ThreatChart: React.FC<Props> = ({ summary }) => {
    const data = {
        labels: ['Malicioso', 'Sospechoso', 'Seguro'],
        datasets: [
            {
                data: [summary.malicious, summary.suspicious, summary.harmless],
                backgroundColor: [
                    '#EF4444', // red-500
                    '#F59E0B', // amber-500
                    '#10B981', // emerald-500
                ],
                borderWidth: 0,
            },
        ],
    };

    const options = {
        responsive: true,
        plugins: {
            legend: {
                position: 'right' as const,
                labels: {
                    color: '#9CA3AF'
                }
            },
            title: {
                display: false,
            },
        },
        cutout: '70%',
    };

    return <Doughnut data={data} options={options} />;
};
