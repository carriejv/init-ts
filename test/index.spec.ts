import { expect } from 'chai';
import { InitTS } from '../src'

describe('InitTS', () => {

    describe ('+ Positive', () => {

        it('Should say \'Hello, world.\'.', () => {
            expect(InitTS.helloWorld()).to.equal('Hello, World.');
        });
        
    });

    describe ('- Negative', () => {

        it('Should not say \'Goodbye, World.\'.', () => {
            expect(InitTS.helloWorld()).to.not.equal('Goodbye, World.');
        });
        
    });

});