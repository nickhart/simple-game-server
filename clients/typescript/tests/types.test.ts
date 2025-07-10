import { GameServerError } from '../src/types';

describe('GameServerError', () => {
  it('should create error with message only', () => {
    const error = new GameServerError('Test error');
    
    expect(error.message).toBe('Test error');
    expect(error.name).toBe('GameServerError');
    expect(error.statusCode).toBeUndefined();
    expect(error.response).toBeUndefined();
    expect(error instanceof Error).toBe(true);
  });

  it('should create error with status code', () => {
    const error = new GameServerError('Not found', 404);
    
    expect(error.message).toBe('Not found');
    expect(error.statusCode).toBe(404);
    expect(error.name).toBe('GameServerError');
  });

  it('should create error with response data', () => {
    const responseData = { error: 'Validation failed', details: ['Name is required'] };
    const error = new GameServerError('Validation error', 422, responseData);
    
    expect(error.message).toBe('Validation error');
    expect(error.statusCode).toBe(422);
    expect(error.response).toEqual(responseData);
  });

  it('should be throwable and catchable', () => {
    expect(() => {
      throw new GameServerError('Test error');
    }).toThrow('Test error');

    try {
      throw new GameServerError('Test error', 500);
    } catch (error) {
      expect(error instanceof GameServerError).toBe(true);
      expect((error as GameServerError).statusCode).toBe(500);
    }
  });
});