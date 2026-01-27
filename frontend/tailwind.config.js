/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                gray: {
                    750: '#2d3748', // 800 is 1f2937, 700 is 374151. 750 custom
                    850: '#1a202c',
                    950: '#0d1117'
                }
            }
        },
    },
    plugins: [],
}
