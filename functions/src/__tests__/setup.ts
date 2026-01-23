// functions/src/__tests__/setup.ts
// Jest 테스트 환경 설정 - Firebase Admin SDK 모킹

// Firebase Admin SDK 모킹
jest.mock('firebase-admin', () => {
  // Firestore 모킹 - 타입 명시
  const mockFirestore: Record<string, jest.Mock> = {};
  mockFirestore.collection = jest.fn(() => mockFirestore);
  mockFirestore.doc = jest.fn(() => mockFirestore);
  mockFirestore.where = jest.fn(() => mockFirestore);
  mockFirestore.limit = jest.fn(() => mockFirestore);
  mockFirestore.orderBy = jest.fn(() => mockFirestore);
  mockFirestore.get = jest.fn();
  mockFirestore.set = jest.fn();
  mockFirestore.update = jest.fn();
  mockFirestore.delete = jest.fn();
  mockFirestore.add = jest.fn();
  mockFirestore.runTransaction = jest.fn();
  mockFirestore.batch = jest.fn(() => ({
    set: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    commit: jest.fn().mockResolvedValue(undefined),
  }));

  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => mockFirestore),
    auth: jest.fn(() => ({
      createCustomToken: jest.fn(),
      getUserByEmail: jest.fn(),
    })),
    messaging: jest.fn(() => ({
      send: jest.fn(),
    })),
  };
});

// Firebase Functions 모킹
jest.mock('firebase-functions/v1', () => ({
  region: jest.fn(() => ({
    https: {
      onRequest: jest.fn(),
      onCall: jest.fn(),
    },
    pubsub: {
      schedule: jest.fn(() => ({
        timeZone: jest.fn(() => ({
          onRun: jest.fn(),
        })),
      })),
    },
    firestore: {
      document: jest.fn(() => ({
        onCreate: jest.fn(),
        onUpdate: jest.fn(),
        onDelete: jest.fn(),
      })),
    },
  })),
  config: jest.fn(() => ({
    kakaopay: {
      admin_key: 'test_admin_key',
      cid: 'TC0ONETIME',
    },
    tosspayments: {
      secret_key: 'test_secret_key',
    },
  })),
  https: {
    HttpsError: class extends Error {
      constructor(public code: string, message: string) {
        super(message);
      }
    },
  },
}));

// Axios 모킹
jest.mock('axios');

// 콘솔 로그 억제 (테스트 출력 정리)
beforeAll(() => {
  jest.spyOn(console, 'log').mockImplementation(() => {});
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'warn').mockImplementation(() => {});
});

afterAll(() => {
  jest.restoreAllMocks();
});

// 각 테스트 후 모킹 초기화
afterEach(() => {
  jest.clearAllMocks();
});
