import { expect } from 'chai';
import { InitTS } from '../src'

describe('InitTS', () => {

    describe ('+ Positive', () => {

        it('Should fail.', () => {
            expect(InitTS.helloWorld()).to.equal('nope');
        });
        
    });

    describe ('- Negative', () => {

        it('Should fail.', () => {
            expect(InitTS.helloWorld()).to.equal('nope');
        });
        
    });

});
