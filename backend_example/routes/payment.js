const express = require('express');
const router = express.Router();
const axios = require('axios');

// 카카오페이 API URL
const KAKAO_PAY_BASE_URL = 'https://open-api.kakaopay.com';

// 임시 결제 정보 저장 (실제로는 DB 사용)
const paymentStore = new Map();

/**
 * 결제 준비 API
 * POST /api/payment/prepare
 */
router.post('/prepare', async (req, res) => {
  try {
    const {
      partner_order_id,
      partner_user_id,
      item_name,
      quantity = 1,
      total_amount,
      tax_free_amount = 0,
      approval_url,
      cancel_url,
      fail_url,
    } = req.body;

    // 필수 파라미터 검증
    if (!partner_order_id || !partner_user_id || !item_name || !total_amount) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '필수 파라미터가 누락되었습니다.',
      });
    }

    // 카카오페이 결제 준비 API 호출
    const response = await axios.post(
      `${KAKAO_PAY_BASE_URL}/online/v1/payment/ready`,
      {
        cid: process.env.KAKAO_CID,
        partner_order_id,
        partner_user_id,
        item_name,
        quantity,
        total_amount,
        tax_free_amount,
        approval_url: approval_url || `${process.env.APP_SCHEME}/approve`,
        cancel_url: cancel_url || `${process.env.APP_SCHEME}/cancel`,
        fail_url: fail_url || `${process.env.APP_SCHEME}/fail`,
      },
      {
        headers: {
          Authorization: `SECRET_KEY ${process.env.KAKAO_ADMIN_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    // 결제 정보 저장 (실제로는 DB에 저장)
    paymentStore.set(response.data.tid, {
      tid: response.data.tid,
      partner_order_id,
      partner_user_id,
      item_name,
      total_amount,
      created_at: new Date().toISOString(),
    });

    console.log(`✅ 결제 준비 완료: ${response.data.tid}`);

    // Flutter 앱으로 응답
    res.json({
      tid: response.data.tid,
      next_redirect_app_url: response.data.next_redirect_app_url,
      next_redirect_mobile_url: response.data.next_redirect_mobile_url,
      next_redirect_pc_url: response.data.next_redirect_pc_url,
      android_app_scheme: response.data.android_app_scheme,
      ios_app_scheme: response.data.ios_app_scheme,
      created_at: response.data.created_at,
    });
  } catch (error) {
    console.error('❌ 결제 준비 실패:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Payment Prepare Failed',
      message: error.response?.data?.msg || error.message,
      details: error.response?.data,
    });
  }
});

/**
 * 결제 승인 API
 * POST /api/payment/approve
 */
router.post('/approve', async (req, res) => {
  try {
    const { tid, partner_order_id, partner_user_id, pg_token } = req.body;

    // 필수 파라미터 검증
    if (!tid || !partner_order_id || !partner_user_id || !pg_token) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '필수 파라미터가 누락되었습니다.',
      });
    }

    // 저장된 결제 정보 확인
    const paymentInfo = paymentStore.get(tid);
    if (!paymentInfo) {
      return res.status(404).json({
        error: 'Not Found',
        message: '결제 정보를 찾을 수 없습니다.',
      });
    }

    // 카카오페이 결제 승인 API 호출
    const response = await axios.post(
      `${KAKAO_PAY_BASE_URL}/online/v1/payment/approve`,
      {
        cid: process.env.KAKAO_CID,
        tid,
        partner_order_id,
        partner_user_id,
        pg_token,
      },
      {
        headers: {
          Authorization: `SECRET_KEY ${process.env.KAKAO_ADMIN_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    console.log(`✅ 결제 승인 완료: ${tid}`);

    // 결제 정보 업데이트
    paymentStore.set(tid, {
      ...paymentInfo,
      approved_at: new Date().toISOString(),
      status: 'approved',
    });

    // Flutter 앱으로 응답
    res.json(response.data);
  } catch (error) {
    console.error('❌ 결제 승인 실패:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Payment Approval Failed',
      message: error.response?.data?.msg || error.message,
      details: error.response?.data,
    });
  }
});

/**
 * 결제 취소 API
 * POST /api/payment/cancel
 */
router.post('/cancel', async (req, res) => {
  try {
    const { tid, cancel_amount, cancel_tax_free_amount = 0 } = req.body;

    // 필수 파라미터 검증
    if (!tid || !cancel_amount) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '필수 파라미터가 누락되었습니다.',
      });
    }

    // 저장된 결제 정보 확인
    const paymentInfo = paymentStore.get(tid);
    if (!paymentInfo) {
      return res.status(404).json({
        error: 'Not Found',
        message: '결제 정보를 찾을 수 없습니다.',
      });
    }

    // 카카오페이 결제 취소 API 호출
    const response = await axios.post(
      `${KAKAO_PAY_BASE_URL}/online/v1/payment/cancel`,
      {
        cid: process.env.KAKAO_CID,
        tid,
        cancel_amount,
        cancel_tax_free_amount,
      },
      {
        headers: {
          Authorization: `SECRET_KEY ${process.env.KAKAO_ADMIN_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    console.log(`✅ 결제 취소 완료: ${tid}`);

    // 결제 정보 업데이트
    paymentStore.set(tid, {
      ...paymentInfo,
      cancelled_at: new Date().toISOString(),
      status: 'cancelled',
    });

    // Flutter 앱으로 응답
    res.json(response.data);
  } catch (error) {
    console.error('❌ 결제 취소 실패:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Payment Cancel Failed',
      message: error.response?.data?.msg || error.message,
      details: error.response?.data,
    });
  }
});

/**
 * 결제 조회 API (선택 사항)
 * GET /api/payment/:tid
 */
router.get('/:tid', async (req, res) => {
  try {
    const { tid } = req.params;

    // 저장된 결제 정보 확인
    const paymentInfo = paymentStore.get(tid);
    if (!paymentInfo) {
      return res.status(404).json({
        error: 'Not Found',
        message: '결제 정보를 찾을 수 없습니다.',
      });
    }

    res.json(paymentInfo);
  } catch (error) {
    console.error('❌ 결제 조회 실패:', error.message);
    res.status(500).json({
      error: 'Payment Query Failed',
      message: error.message,
    });
  }
});

module.exports = router;
