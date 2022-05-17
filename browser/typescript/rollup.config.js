// import { uglify } from "rollup-plugin-uglify";
// import sourcemaps from 'rollup-plugin-sourcemaps';
import typescript from '@rollup/plugin-typescript';

export default [
    {
        treeshake: false,
        input: 'lib/htmlApp.ts',
        plugins: [
            typescript(),
            // sourcemaps(),
            // uglify(),
        ],
        output: {
            // sourcemap: true,
            name: 'media',
            // file: "../../packages/media/assets/media.js",  
            file: "./htmlapp.js",
            format: 'es'
        }
    },
    {
        treeshake: false,
        input: 'lib/media.ts',
        plugins: [
            typescript(),
            // sourcemaps(),
            // uglify(),
        ],
        output: {
            // sourcemap: true,
            name: 'media',
            file: "../../packages/media/assets/media.js",  
            format: 'es'
        }
    }
]
