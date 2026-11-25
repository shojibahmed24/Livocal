let activeWalletsList = [];
    let rawP2PRecords = [];
    let currentP2PFilter = 'all';

    function escapeHtml(str) {
      if (str === null || str === undefined) return '';
      return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
    }

    function getAdminSecret() {
      return sessionStorage.getItem('livocal_admin_secret') || '';
    }

    function saveAdminSecret() {
      const val = document.getElementById('adminSecretInput').value.trim();
      if (val) {
        sessionStorage.setItem('livocal_admin_secret', val);
        localStorage.removeItem('livocal_admin_secret'); // Clean up any persistent disk storage
        showToast('Admin Secret saved securely in active session!');
        fetchDashboardData();
      } else {
        sessionStorage.removeItem('livocal_admin_secret');
        localStorage.removeItem('livocal_admin_secret');
        showToast('Admin Secret removed from session.', true);
      }
    }

    function saveAdminSecretFromModal() {
      const val = document.getElementById('modalSecretInput').value.trim();
      if (val) {
        sessionStorage.setItem('livocal_admin_secret', val);
        localStorage.removeItem('livocal_admin_secret'); // Clean up any persistent disk storage
        document.getElementById('adminSecretInput').value = val;
        closeSecretModal();
        showToast('Admin Secret saved in active session!');
        fetchDashboardData();
      } else {
        showToast('Please enter a valid secret.', true);
      }
    }

    function logoutAdmin() {
      sessionStorage.removeItem('livocal_admin_secret');
      localStorage.removeItem('livocal_admin_secret');
      // Drop the HttpOnly session cookie as well.
      fetch('/admin/logout', { method: 'POST' }).catch(() => {});
      const input = document.getElementById('adminSecretInput');
      if (input) input.value = '';
      const modalInput = document.getElementById('modalSecretInput');
      if (modalInput) modalInput.value = '';
      closeSecretModal();
      showToast('Admin logged out. Session cleared.', false);
      const payTbody = document.getElementById('paymentsTableBody');
      if (payTbody) payTbody.innerHTML = '<tr><td colspan="9" style="text-align:center; padding:30px; color:var(--text-muted);">Please log in with Admin Secret.</td></tr>';
      const wallTbody = document.getElementById('walletsTableBody');
      if (wallTbody) wallTbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:30px; color:var(--text-muted);">Please log in with Admin Secret.</td></tr>';
      const rechTbody = document.getElementById('rechargesTableBody');
      if (rechTbody) rechTbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:30px; color:var(--text-muted);">Please log in with Admin Secret.</td></tr>';
      const ledgTbody = document.getElementById('ledgerTableBody');
      if (ledgTbody) ledgTbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:30px; color:var(--text-muted);">Please log in with Admin Secret.</td></tr>';
    }

    function openSecretModal() {
      document.getElementById('modalSecretInput').value = getAdminSecret();
      document.getElementById('secretModal').classList.add('active');
    }

    function closeSecretModal() {
      document.getElementById('secretModal').classList.remove('active');
    }

    document.addEventListener('DOMContentLoaded', () => {
      // Migrate legacy localStorage if present, then purge from localStorage
      let activeSecret = sessionStorage.getItem('livocal_admin_secret');
      if (!activeSecret && localStorage.getItem('livocal_admin_secret')) {
        activeSecret = localStorage.getItem('livocal_admin_secret');
        sessionStorage.setItem('livocal_admin_secret', activeSecret);
        localStorage.removeItem('livocal_admin_secret');
      }
      if (activeSecret) {
        document.getElementById('adminSecretInput').value = activeSecret;
        fetchDashboardData();
      } else {
        // No secret stored: the Basic-auth gate already set an HttpOnly session
        // cookie, so the dashboard can load without asking for the secret.
        fetch('/api/admin/whoami')
          .then((r) => {
            if (r.ok) {
              fetchDashboardData();
            } else {
              showToast('Please enter Admin Secret to load live dashboard data.', true);
            }
          })
          .catch(() => {
            showToast('Please enter Admin Secret to load live dashboard data.', true);
          });
      }
      loadDepositInfo();

      // Safe Event Delegation (Eliminates inline onclick and completely stops Stored XSS)
      const payTbody = document.getElementById('paymentsTableBody');
      if (payTbody) {
        payTbody.addEventListener('click', (e) => {
          const approveBtn = e.target.closest('.btn-action-approve');
          if (approveBtn) {
            handlePaymentAction(approveBtn.dataset.id, 'approve', Number(approveBtn.dataset.minutes));
            return;
          }
          const rejectBtn = e.target.closest('.btn-action-reject');
          if (rejectBtn) {
            handlePaymentAction(rejectBtn.dataset.id, 'reject');
            return;
          }
          const verifyBtn = e.target.closest('.btn-action-verify');
          if (verifyBtn) {
            verifyOnChainPayment(verifyBtn.dataset.method, verifyBtn.dataset.trx, Number(verifyBtn.dataset.amount));
            return;
          }
        });
      }

      const walTbody = document.getElementById('walletsTableBody');
      if (walTbody) {
        walTbody.addEventListener('click', (e) => {
          const topupBtn = e.target.closest('.btn-wallet-topup');
          if (topupBtn && topupBtn.dataset.target) {
            openTopUpForUser(topupBtn.dataset.target);
          }
        });
      }

      const p2pTbody = document.getElementById('p2pTableBody');
      if (p2pTbody) {
        p2pTbody.addEventListener('click', (e) => {
          const verifyBtn = e.target.closest('.btn-p2p-verify');
          if (verifyBtn && verifyBtn.dataset.id) {
            handleP2PAction(verifyBtn.dataset.id, 'verify');
            return;
          }
          const flagBtn = e.target.closest('.btn-p2p-flag');
          if (flagBtn && flagBtn.dataset.id) {
            handleP2PAction(flagBtn.dataset.id, 'flag');
            return;
          }
          const copyBtn = e.target.closest('.btn-p2p-copy');
          if (copyBtn && copyBtn.dataset.text) {
            copyText(copyBtn.dataset.text);
            return;
          }
        });
      }

      // Auto-refresh every 30 seconds if secret is configured
      setInterval(() => {
        if (getAdminSecret()) fetchDashboardData();
      }, 30000);
    });

    function showToast(msg, isError = false) {
      const toast = document.getElementById('toast');
      toast.innerText = msg;
      toast.style.borderLeftColor = isError ? 'var(--danger)' : 'var(--primary)';
      toast.style.display = 'block';
      setTimeout(() => { toast.style.display = 'none'; }, 3500);
    }

    function copyText(txt) {
      navigator.clipboard.writeText(txt);
      showToast(`Copied to clipboard: ${txt}`);
    }

    function switchTab(tabId) {
      // Hide all tabs
      document.querySelectorAll('.tab-content').forEach(card => card.style.display = 'none');
      document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
      document.querySelectorAll('.mobile-nav-item').forEach(btn => btn.classList.remove('active'));
      document.querySelectorAll('.side-nav-item').forEach(btn => btn.classList.remove('active'));

      const targetTab = document.getElementById(`tab-${tabId}`);
      if (targetTab) targetTab.style.display = 'block';

      // Desktop active tab (some tabs live only in the sidebar)
      const desktopBtnMap = {
        'payments': 'tabBtnPayments',
        'wallets': 'tabBtnWallets',
        'p2p': 'tabBtnP2P',
        'recharges': 'tabBtnRecharges',
        'ledger': 'tabBtnLedger',
        'gateways': 'tabBtnGateways',
      };
      if (desktopBtnMap[tabId]) {
        const dBtn = document.getElementById(desktopBtnMap[tabId]);
        if (dBtn) dBtn.classList.add('active');
      }

      const sideBtnMap = {
        'overview': 'sideNavOverview',
        'payments': 'sideNavPayments',
        'wallets': 'sideNavWallets',
        'p2p': 'sideNavP2P',
        'recharges': 'sideNavRecharges',
        'ledger': 'sideNavLedger',
        'gateways': 'sideNavGateways',
        'users': 'sideNavUsers',
        'reports': 'sideNavReports',
        'health': 'sideNavHealth',
        'audit': 'sideNavAudit',
      };
      const sBtn = document.getElementById(sideBtnMap[tabId]);
      if (sBtn) sBtn.classList.add('active');

      // Mobile active item
      const mobBtnMap = {
        'payments': 'mobNavPayments',
        'wallets': 'mobNavWallets',
        'p2p': 'mobNavP2P',
        'recharges': 'mobNavRecharges',
        'ledger': 'mobNavRecharges',
        'gateways': 'mobNavGateways',
        'users': 'mobNavUsers',
        'reports': 'mobNavReports',
        'health': 'mobNavHealth',
        'audit': 'mobNavAudit',
      };
      if (mobBtnMap[tabId]) {
        const mBtn = document.getElementById(mobBtnMap[tabId]);
        if (mBtn) mBtn.classList.add('active');
      }

      // Lazy load the operations tabs
      if (tabId === 'users') loadUsers();
      if (tabId === 'reports') loadReports();
      if (tabId === 'health') loadHealth();
      if (tabId === 'audit') loadAudit();

      // Scroll smoothly to top on mobile tab switch
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    async function loadDepositInfo() {
      const secret = getAdminSecret();
      const headers = secret ? { 'x-admin-secret': secret } : {};
      try {
        const res = await fetch('/api/wallet/deposit-info', { headers });
        if (res.ok) {
          const data = await res.json();
          if (data.success && data.depositInfo) {
            const info = data.depositInfo;
            if (info.bkash?.number) document.getElementById('gwBkash').innerText = info.bkash.number;
            if (info.nagad?.number) document.getElementById('gwNagad').innerText = info.nagad.number;
            if (info.binancePay?.payId) document.getElementById('gwBinance').innerText = info.binancePay.payId;
            if (info.cryptoUsdt?.trc20?.address) document.getElementById('gwTrc20').innerText = info.cryptoUsdt.trc20.address;
            if (info.cryptoUsdt?.bep20?.address) document.getElementById('gwBep20').innerText = info.cryptoUsdt.bep20.address;
          }
        }
      } catch (err) {
        console.warn('Could not fetch deposit gateways:', err.message);
      }
    }

    async function fetchDashboardData() {
      const secret = getAdminSecret();
      if (!secret) return;
      const headers = { 'x-admin-secret': secret };

      try {
        // 1. KPI Metrics
        const metricsRes = await fetch('/api/admin/metrics', { headers });
        if (metricsRes.ok) {
          const data = await metricsRes.json();
          const m = data.metrics;
          document.getElementById('kpiRevenue').innerText = `৳${(m.totalRetailBdt + m.totalRechargeRevenueBdt).toLocaleString()}`;
          document.getElementById('kpiGeminiCost').innerText = `৳${m.totalGeminiCostBdt.toLocaleString()}`;
          document.getElementById('kpiGeminiCostUsd').innerText = `$${m.totalGeminiCostUsd} USD (@$0.035/min ≈ ৳4.2)`;
          document.getElementById('kpiProfit').innerText = `৳${(m.netProfitBdt + m.totalRechargeRevenueBdt).toLocaleString()}`;
          document.getElementById('kpiMargin').innerText = `Margin: ${m.profitMarginPercent}`;
          document.getElementById('kpiBilledMinutes').innerText = `${m.totalBilledMinutes.toLocaleString()} min`;
          document.getElementById('kpiUsers').innerText = `${m.totalUsers.toLocaleString()}`;
        } else if (metricsRes.status === 403 || metricsRes.status === 401) {
          showToast('Invalid Admin Secret! Please check your key.', true);
        }

        // 2. Billing Ledger
        const ledgerRes = await fetch('/api/admin/billing-ledger', { headers });
        if (ledgerRes.ok) {
          const data = await ledgerRes.json();
          renderLedgerTable(data.records || []);
        }

        // 3. Wallets
        const walletsRes = await fetch('/api/admin/wallets', { headers });
        if (walletsRes.ok) {
          const data = await walletsRes.json();
          activeWalletsList = data.wallets || [];
          renderWalletsTable(activeWalletsList);
        }

        // 4. Recharges
        const rechargesRes = await fetch('/api/admin/recharges', { headers });
        if (rechargesRes.ok) {
          const data = await rechargesRes.json();
          renderRechargesTable(data.recharges || []);
        }

        // 5. Payment Requests
        const paymentsRes = await fetch('/api/admin/payment-requests', { headers });
        if (paymentsRes.ok) {
          const data = await paymentsRes.json();
          const reqs = data.requests || [];
          const pendingCount = reqs.filter(r => r.status === 'pending').length;
          
          const badgeDesk = document.getElementById('pendingPaymentsBadge');
          if (badgeDesk) {
            badgeDesk.innerText = pendingCount;
            badgeDesk.style.display = pendingCount > 0 ? 'inline-block' : 'none';
          }
          const badgeMob = document.getElementById('mobBadgePayments');
          if (badgeMob) {
            badgeMob.innerText = pendingCount;
            badgeMob.style.display = pendingCount > 0 ? 'inline-block' : 'none';
          }
          renderPaymentsTable(reqs);
        }

        // 6. In-Chat P2P Payments & Transfers
        const p2pRes = await fetch('/api/admin/p2p-transfers', { headers });
        if (p2pRes.ok) {
          const data = await p2pRes.json();
          const s = data.stats || {};
          const transfers = data.transfers || [];
          const payments = data.payments || [];
          
          if (document.getElementById('p2pKpiMinutes')) {
            document.getElementById('p2pKpiMinutes').innerText = `${(s.totalMinutesTransferred || 0).toLocaleString()} min`;
          }
          if (document.getElementById('p2pKpiTransfersCount')) {
            document.getElementById('p2pKpiTransfersCount').innerText = `${transfers.length} wallet transfers`;
          }
          if (document.getElementById('p2pKpiBdt')) {
            document.getElementById('p2pKpiBdt').innerText = `৳${(s.totalBdtAmount || 0).toLocaleString()}`;
          }
          if (document.getElementById('p2pKpiUsdt')) {
            document.getElementById('p2pKpiUsdt').innerText = `$${(s.totalCryptoUsdtAmount || 0).toLocaleString()} USDT`;
          }
          if (document.getElementById('p2pKpiTotalEvents')) {
            document.getElementById('p2pKpiTotalEvents').innerText = `${transfers.length + payments.length}`;
          }

          const totalPendingP2p = payments.filter(p => p.status === 'reported').length;
          const badgeDesk = document.getElementById('p2pCountBadge');
          if (badgeDesk) {
            badgeDesk.innerText = totalPendingP2p;
            badgeDesk.style.display = totalPendingP2p > 0 ? 'inline-block' : 'none';
          }
          const badgeMob = document.getElementById('mobBadgeP2P');
          if (badgeMob) {
            badgeMob.innerText = totalPendingP2p;
            badgeMob.style.display = totalPendingP2p > 0 ? 'inline-block' : 'none';
          }

          rawP2PRecords = [
            ...transfers.map(t => ({ ...t, kind: 'minute_transfer' })),
            ...payments.map(p => ({ ...p, kind: 'payment' }))
          ].sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));

          filterP2PTable();
        }

      } catch (err) {
        console.error('Error fetching dashboard data:', err);
      }
    }

    function renderLedgerTable(records) {
      const tbody = document.getElementById('ledgerTableBody');
      if (!records.length) {
        tbody.innerHTML = `<tr><td colspan="10" style="text-align:center; padding:28px; color:var(--text-muted);">No live call records recorded yet.</td></tr>`;
        return;
      }

      tbody.innerHTML = records.map(r => {
        const timeStr = r.timestamp ? escapeHtml(new Date(r.timestamp).toLocaleTimeString([], { hour:'2-digit', minute:'2-digit', second:'2-digit' })) : '-';
        const rawCall = r.callId || '';
        const shortCall = rawCall.length > 14 ? rawCall.substring(0, 12) + '...' : rawCall;
        const callerStr = r.callerId ? r.callerId.substring(0, 10) : '-';
        const calleeStr = r.calleeId ? r.calleeId.substring(0, 10) : '-';

        return `
          <tr>
            <td><code style="color:var(--accent); font-weight:bold;" title="${escapeHtml(rawCall)}">${escapeHtml(shortCall || '-')}</code></td>
            <td>${timeStr}</td>
            <td><code style="font-size:12px;">${escapeHtml(callerStr)}</code></td>
            <td><code style="font-size:12px;">${escapeHtml(calleeStr)}</code></td>
            <td><span class="badge badge-info">Min #${Number(r.minuteIndex) || 1}</span></td>
            <td>${Number(r.durationSeconds) || 60}s</td>
            <td style="color:#fb7185; font-weight:600;">$${Number(r.geminiCostUsd) || 0.035}</td>
            <td style="color:#34d399; font-weight:600;">৳${Number(r.retailRateBdt) || 20.0}</td>
            <td style="color:#38bdf8; font-weight:bold;">+৳${Number(r.netProfitBdt) || 15.8}</td>
            <td><span class="badge badge-success">✓ Settled</span></td>
          </tr>
        `;
      }).join('');
    }

    function renderWalletsTable(wallets) {
      const tbody = document.getElementById('walletsTableBody');
      if (!wallets.length) {
        tbody.innerHTML = `<tr><td colspan="8" style="text-align:center; padding:28px; color:var(--text-muted);">No registered wallets found.</td></tr>`;
        return;
      }

      tbody.innerHTML = wallets.map(w => {
        const isTrialActive = w.trialActive && (!w.trialExpiresAt || new Date(w.trialExpiresAt) > new Date());
        const trialBadge = isTrialActive
          ? `<span class="badge badge-success">Active (${Number(w.trialMinutes) || 0}m)</span>`
          : `<span class="badge badge-danger">Expired</span>`;
        const userTarget = escapeHtml(w.phone || w.userId || '');

        return `
          <tr>
            <td><strong>${escapeHtml(w.name || 'Freelancer')}</strong></td>
            <td><code style="color:var(--text-main); font-weight:bold;">${escapeHtml(w.phone || '-')}</code></td>
            <td><span style="font-weight:700; color:#34d399; font-size:14.5px;">💎 ${Number(w.balanceMinutes) || 0}m</span></td>
            <td>⏱️ ${Number(w.trialMinutes) || 0}m</td>
            <td>${trialBadge}</td>
            <td style="font-size:12px; color:var(--text-muted);">${w.trialExpiresAt ? escapeHtml(new Date(w.trialExpiresAt).toLocaleDateString()) : '-'}</td>
            <td>${Number(w.totalMinutesUsed) || 0}m</td>
            <td>
              <button class="btn btn-secondary btn-wallet-topup" data-target="${userTarget}" style="padding:4px 10px; font-size:12px;">
                ➕ Top-Up
              </button>
            </td>
          </tr>
        `;
      }).join('');
    }

    function filterWallets() {
      const query = document.getElementById('walletSearchInput').value.trim().toLowerCase();
      if (!query) {
        renderWalletsTable(activeWalletsList);
        return;
      }
      const filtered = activeWalletsList.filter(w =>
        (w.phone && w.phone.toLowerCase().includes(query)) ||
        (w.name && w.name.toLowerCase().includes(query)) ||
        (w.userId && w.userId.toLowerCase().includes(query))
      );
      renderWalletsTable(filtered);
    }

    function renderRechargesTable(recharges) {
      const tbody = document.getElementById('rechargesTableBody');
      if (!recharges.length) {
        tbody.innerHTML = `<tr><td colspan="8" style="text-align:center; padding:28px; color:var(--text-muted);">No recharge ledger records yet.</td></tr>`;
        return;
      }

      tbody.innerHTML = recharges.map(rc => {
        const dateStr = rc.createdAt ? escapeHtml(new Date(rc.createdAt).toLocaleString()) : '-';
        const curr = rc.currency === 'USDT' ? `$${Number(rc.amountPaid) || 0} USDT` : `৳${Number(rc.amountPaid) || 0}`;
        const rawTx = rc.transactionId || '';
        const shortTx = rawTx.length > 20 ? rawTx.substring(0, 18) + '...' : rawTx;

        return `
          <tr>
            <td><code style="color:var(--accent); font-weight:600;" title="${escapeHtml(rawTx)}">${escapeHtml(shortTx || '-')}</code></td>
            <td><code>${escapeHtml(rc.userPhone || rc.userId || '-')}</code></td>
            <td><span class="badge badge-info">${escapeHtml(rc.packId || 'Custom')}</span></td>
            <td style="color:#34d399; font-weight:bold;">+${Number(rc.minutesAdded) || 0}m</td>
            <td style="font-weight:700;">${curr}</td>
            <td>${escapeHtml(rc.paymentMethod || 'Manual')}</td>
            <td><span class="badge badge-success">✓ Completed</span></td>
            <td style="font-size:12px; color:var(--text-muted);">${dateStr}</td>
          </tr>
        `;
      }).join('');
    }

    function renderPaymentsTable(requests) {
      const tbody = document.getElementById('paymentsTableBody');
      if (!requests.length) {
        tbody.innerHTML = `<tr><td colspan="10" style="text-align:center; padding:28px; color:var(--text-muted);">No pending payment verification requests.</td></tr>`;
        return;
      }

      tbody.innerHTML = requests.map(r => {
        const timeStr = r.createdAt ? escapeHtml(new Date(r.createdAt).toLocaleString()) : '-';
        let statusBadge = `<span class="badge badge-warning">⏳ Pending</span>`;
        if (r.status === 'approved') {
          statusBadge = `<span class="badge badge-success">✓ Approved</span>`;
        } else if (r.status === 'rejected') {
          statusBadge = `<span class="badge badge-danger">✕ Rejected</span>`;
        }

        // Method Icon & Tag
        let methodHtml = `<span class="badge badge-info">${escapeHtml(r.paymentMethod || 'bKash')}</span>`;
        if (r.paymentMethod === 'bKash') {
          methodHtml = `<span class="badge badge-bkash">📱 bKash</span>`;
        } else if (r.paymentMethod === 'Nagad') {
          methodHtml = `<span class="badge badge-nagad">📱 Nagad</span>`;
        } else if (r.paymentMethod === 'Binance_Pay') {
          methodHtml = `<span class="badge badge-binance">🟡 Binance Pay</span>`;
        } else if (r.paymentMethod && r.paymentMethod.startsWith('Crypto_USDT')) {
          const net = r.paymentMethod.includes('TRC20') ? 'TRC-20' : 'BEP-20';
          methodHtml = `<span class="badge badge-crypto">💎 USDT (${net})</span>`;
        }

        const amountFormatted = r.currency === 'USDT' ? `$${Number(r.amount) || 0} USDT` : `৳${Number(r.amount) || 0}`;
        const sender = escapeHtml(r.senderIdentifier || r.senderPhone || '-');
        const userDisplay = escapeHtml(r.userPhone || r.userId || '-');
        const packDisplay = escapeHtml(r.packId || 'Custom');

        const promoBadge = r.promoCode
          ? `<div style="margin-top:2px;"><span class="badge badge-info" style="font-size:10px;">🏷️ ${escapeHtml(r.promoCode)} (+${Number(r.bonusMinutes) || 0}m)</span></div>`
          : '';

        // Explorer links (strictly sanitize hash for URL)
        let explorerHtml = '';
        const safeHash = (r.trxId || '').replace(/[^a-zA-Z0-9]/g, '');
        if (r.paymentMethod === 'Crypto_USDT_TRC20' && safeHash) {
          const clean = safeHash.replace(/^0x/, '');
          explorerHtml = `<div style="margin-top:3px;"><a href="https://tronscan.org/#/transaction/${clean}" target="_blank" rel="noopener noreferrer" style="color:var(--accent); font-size:11px; text-decoration:underline;">🔗 View on Tronscan</a></div>`;
        } else if (r.paymentMethod === 'Crypto_USDT_BEP20' && safeHash) {
          const clean = safeHash.startsWith('0x') ? safeHash : `0x${safeHash}`;
          explorerHtml = `<div style="margin-top:3px;"><a href="https://bscscan.com/tx/${clean}" target="_blank" rel="noopener noreferrer" style="color:var(--accent); font-size:11px; text-decoration:underline;">🔗 View on BscScan</a></div>`;
        }

        const isCryptoMethod = r.paymentMethod && r.paymentMethod.startsWith('Crypto_USDT');
        const verifyBtn = isCryptoMethod
          ? `<button class="btn btn-secondary btn-action-verify" data-method="${escapeHtml(r.paymentMethod)}" data-trx="${escapeHtml(r.trxId)}" data-amount="${Number(r.amount) || 0}" style="padding:4px 8px; font-size:11px; background:#0f172a; color:#38bdf8; border:1px solid #38bdf8;">🔍 Verify On-Chain</button>`
          : '';

        const actionBtns = r.status === 'pending'
          ? `
            <div style="display:flex; flex-direction:column; gap:6px;">
              <div style="display:flex; gap:6px;">
                <button class="btn btn-primary btn-action-approve" data-id="${escapeHtml(r.id)}" data-minutes="${Number(r.minutes) || 0}" style="padding:5px 10px; font-size:12px;">
                  ✓ Approve
                </button>
                <button class="btn btn-secondary btn-action-reject" data-id="${escapeHtml(r.id)}" style="padding:5px 10px; font-size:12px; color:var(--danger);">
                  ✕ Reject
                </button>
              </div>
              ${verifyBtn}
            </div>
          `
          : `<div style="font-size:12px; color:var(--text-muted);">${escapeHtml(r.approvedBy || r.rejectedBy || '-')}</div>${verifyBtn ? `<div style="margin-top:4px;">${verifyBtn}</div>` : ''}`;

        const rawTrx = r.trxId || '';
        const shortTrx = rawTrx.length > 20 ? rawTrx.substring(0, 18) + '...' : rawTrx;

        return `
          <tr>
            <td>
              <code style="color:var(--accent); font-weight:bold; font-size:12.5px;" title="${escapeHtml(rawTrx)}">${escapeHtml(shortTrx || '-')}</code>
              ${explorerHtml}
            </td>
            <td><code>${userDisplay}</code></td>
            <td><strong style="color:#f8fafc; font-size:12px;">${sender}</strong></td>
            <td><span class="badge badge-info">${packDisplay}</span>${promoBadge}</td>
            <td style="color:#34d399; font-weight:bold; font-size:14px;">+${Number(r.minutes) || 0}m</td>
            <td style="font-weight:700; color:#fff;">${amountFormatted}</td>
            <td>${methodHtml}</td>
            <td style="font-size:12px; color:var(--text-muted);">${timeStr}</td>
            <td>${statusBadge}</td>
            <td>${actionBtns}</td>
          </tr>
        `;
      }).join('');
    }

    function setP2PFilter(filter) {
      currentP2PFilter = filter;
      document.querySelectorAll('.p2p-filter-btn').forEach(btn => {
        btn.style.borderColor = 'var(--card-border)';
        btn.style.color = 'var(--text-main)';
      });
      const activeBtnMap = {
        'all': 'filterP2PAll',
        'wallet': 'filterP2PWallet',
        'mfs': 'filterP2PMfs',
        'crypto': 'filterP2PCrypto',
      };
      const activeEl = document.getElementById(activeBtnMap[filter]);
      if (activeEl) {
        activeEl.style.borderColor = 'var(--primary)';
        activeEl.style.color = 'var(--primary)';
      }
      filterP2PTable();
    }

    function filterP2PTable() {
      const query = (document.getElementById('searchP2PInput')?.value || '').toLowerCase().trim();
      let filtered = rawP2PRecords;

      if (currentP2PFilter === 'wallet') {
        filtered = filtered.filter(r => r.kind === 'minute_transfer');
      } else if (currentP2PFilter === 'mfs') {
        filtered = filtered.filter(r => {
          const m = (r.type || r.methodDisplay || '').toLowerCase();
          return m.includes('bkash') || m.includes('nagad') || (r.currency || '').toUpperCase() === 'BDT';
        });
      } else if (currentP2PFilter === 'crypto') {
        filtered = filtered.filter(r => {
          const m = (r.type || r.methodDisplay || '').toLowerCase();
          return m.includes('crypto') || m.includes('usdt') || m.includes('binance') || (r.currency || '').toUpperCase() === 'USDT';
        });
      }

      if (query) {
        filtered = filtered.filter(r => {
          const matchId = (r.id || '').toLowerCase().includes(query);
          const matchTx = (r.txId || '').toLowerCase().includes(query);
          const matchFrom = (r.fromUserId || r.senderId || r.senderPhone || '').toLowerCase().includes(query);
          const matchTo = (r.toUserId || r.recipientId || r.recipientPhone || r.recipientName || '').toLowerCase().includes(query);
          const matchNote = (r.note || '').toLowerCase().includes(query);
          return matchId || matchTx || matchFrom || matchTo || matchNote;
        });
      }

      renderP2PTable(filtered);
    }

    function renderP2PTable(records) {
      const tbody = document.getElementById('p2pTableBody');
      if (!tbody) return;
      if (!records || !records.length) {
        tbody.innerHTML = `<tr><td colspan="9" style="text-align:center; padding:28px; color:var(--text-muted);">No in-chat P2P payment or transfer records matching criteria.</td></tr>`;
        return;
      }

      tbody.innerHTML = records.map(r => {
        const timeStr = r.createdAt ? escapeHtml(new Date(r.createdAt).toLocaleString()) : '-';
        const isTransfer = r.kind === 'minute_transfer';

        // Method Badge
        let methodHtml = `<span class="badge" style="background:rgba(16,185,129,0.15); color:#34d399;">⚡ Wallet Minutes</span>`;
        if (!isTransfer) {
          const m = (r.type || r.methodDisplay || '').toLowerCase();
          if (m.includes('bkash')) {
            methodHtml = `<span class="badge badge-bkash">📱 bKash</span>`;
          } else if (m.includes('nagad')) {
            methodHtml = `<span class="badge badge-nagad">📱 Nagad</span>`;
          } else if (m.includes('binance')) {
            methodHtml = `<span class="badge badge-binance">🟡 Binance Pay</span>`;
          } else {
            methodHtml = `<span class="badge badge-crypto">💎 Crypto USDT</span>`;
          }
        }

        // Sender & Recipient
        const senderStr = escapeHtml(r.senderPhone || r.fromUserId || r.senderId || '-');
        const recipientStr = escapeHtml(r.recipientName || r.recipientPhone || r.toUserId || r.recipientId || '-');

        // Amount Display
        let amountHtml = '';
        if (isTransfer) {
          amountHtml = `<span style="color:#34d399; font-weight:800; font-size:14px;">⚡ +${Number(r.minutes) || 0}m</span>`;
        } else {
          const amt = r.amount ? escapeHtml(String(r.amount)) : '0';
          amountHtml = `<span style="font-weight:800; font-size:14px; color:#fff;">${amt}</span>`;
        }

        // TrxID / Ref
        const rawTx = r.txId || r.id || '';
        const shortTx = rawTx.length > 16 ? rawTx.substring(0, 14) + '...' : rawTx;
        const trxHtml = rawTx
          ? `<div style="display:flex; align-items:center; gap:6px;">
               <code style="color:var(--accent); font-weight:600;" title="${escapeHtml(rawTx)}">${escapeHtml(shortTx)}</code>
               <button class="btn btn-secondary btn-p2p-copy" data-text="${escapeHtml(rawTx)}" style="padding:2px 6px; font-size:10px;">📋</button>
             </div>`
          : '-';

        // Status Badge
        let statusBadge = `<span class="badge badge-success">✓ Completed</span>`;
        if (r.status === 'reported') {
          statusBadge = `<span class="badge badge-warning">⏳ Reported</span>`;
        } else if (r.status === 'verified') {
          statusBadge = `<span class="badge badge-success">✓ Verified</span>`;
        } else if (r.status === 'flagged') {
          statusBadge = `<span class="badge badge-danger">⚠️ Flagged</span>`;
        }

        // Action Buttons
        let actionsHtml = `<span style="font-size:11px; color:var(--text-muted);">-</span>`;
        if (!isTransfer && (r.status === 'reported' || r.status === 'flagged')) {
          actionsHtml = `
            <div style="display:flex; gap:4px;">
              <button class="btn btn-primary btn-p2p-verify" data-id="${escapeHtml(r.id)}" style="padding:3px 8px; font-size:11px;">✓ Verify</button>
              <button class="btn btn-secondary btn-p2p-flag" data-id="${escapeHtml(r.id)}" style="padding:3px 8px; font-size:11px; color:var(--danger);">⚠️ Flag</button>
            </div>
          `;
        } else if (!isTransfer && r.status === 'verified') {
          actionsHtml = `<span style="font-size:11px; color:#34d399; font-weight:600;">Confirmed</span>`;
        }

        return `
          <tr>
            <td style="font-size:12px; color:var(--text-muted);">${timeStr}</td>
            <td>${methodHtml}</td>
            <td><code style="font-size:12px;">${senderStr}</code></td>
            <td><code style="font-size:12px;">${recipientStr}</code></td>
            <td>${amountHtml}</td>
            <td>${trxHtml}</td>
            <td style="font-size:12px; max-width:140px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="${escapeHtml(r.note || '')}">${escapeHtml(r.note || '-')}</td>
            <td>${statusBadge}</td>
            <td>${actionsHtml}</td>
          </tr>
        `;
      }).join('');
    }

    async function handleP2PAction(paymentId, action) {
      const confirmMsg = action === 'verify'
        ? 'Are you sure you want to mark this reported in-chat payment as VERIFIED?'
        : 'Are you sure you want to FLAG this in-chat payment for investigation?';

      if (!confirm(confirmMsg)) return;

      const secret = getAdminSecret();
      try {
        const res = await fetch('/api/admin/p2p-payment/action', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-admin-secret': secret,
          },
          body: JSON.stringify({
            paymentId,
            action,
            note: 'Updated from Admin Control Room',
          }),
        });

        const data = await res.json();
        if (res.ok && data.success) {
          showToast(`P2P payment status updated to ${data.status}!`);
          fetchDashboardData();
        } else {
          showToast(`Failed: ${data.error || 'Action failed'}`, true);
        }
      } catch (err) {
        showToast(`Error: ${err.message}`, true);
      }
    }

    async function verifyOnChainPayment(paymentMethod, trxId, expectedAmount) {
      const secret = getAdminSecret();
      if (!secret) {
        showToast('Please save your Admin Secret first!', true);
        return;
      }

      showToast('Scanning live blockchain node...', false);

      try {
        const res = await fetch('/api/admin/verify-onchain', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-admin-secret': secret,
          },
          body: JSON.stringify({ paymentMethod, trxId, expectedAmount }),
        });

        const data = await res.json();
        if (data.verified) {
          const d = data.details || {};
          alert(`✅ ON-CHAIN VERIFICATION CONFIRMED!\n\n` +
                `Status: ${data.status} (Confirmed: ${data.confirmed ? 'Yes' : 'Mining'})\n` +
                `Sender: ${d.from}\n` +
                `Recipient (Our Wallet): ${d.to}\n` +
                `Deposited Amount: $${d.amountTransferred || expectedAmount} USDT\n` +
                `Expected Amount: $${d.expectedAmount || expectedAmount} USDT\n\n` +
                `This transaction is 100% verified on-chain and safe to approve.`);
        } else {
          alert(`⚠️ ON-CHAIN VERIFICATION MISMATCH OR PENDING:\n\n` +
                `Message: ${data.error || 'Transaction not found or recipient wallet did not match'}\n` +
                `Status: ${data.status || 'UNCONFIRMED'}\n\n` +
                `Please verify on the block explorer before approving.`);
        }
      } catch (err) {
        alert(`On-chain verification error: ${err.message}`);
      }
    }

    async function handlePaymentAction(requestId, action, minutes) {
      const confirmMsg = action === 'approve'
        ? `Are you sure you want to approve this payment and credit ${minutes} minutes to the freelancer's wallet?`
        : 'Are you sure you want to reject this payment request?';

      if (!confirm(confirmMsg)) return;

      const secret = getAdminSecret();
      try {
        const res = await fetch('/api/admin/payment-request/action', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-admin-secret': secret,
          },
          body: JSON.stringify({
            requestId,
            action,
            adminName: 'Admin Control Room',
          }),
        });

        const data = await res.json();
        if (res.ok && data.success) {
          showToast(action === 'approve' ? `Payment approved! ${minutes} minutes credited.` : 'Payment request rejected.');
          fetchDashboardData();
        } else {
          showToast(`Failed: ${data.error || 'Action could not be completed'}`, true);
        }
      } catch (err) {
        showToast(`Error: ${err.message}`, true);
      }
    }

    function openTopUpModal() {
      document.getElementById('topUpModal').classList.add('active');
      if (!document.getElementById('topupIdempotencyKey').value) {
        document.getElementById('topupIdempotencyKey').value = 'topup_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8);
      }
    }

    function openTopUpForUser(identifier) {
      const currentPhone = document.getElementById('topupPhone').value;
      if (currentPhone !== identifier) {
        document.getElementById('topupIdempotencyKey').value = '';
      }
      document.getElementById('topupPhone').value = identifier;
      openTopUpModal();
    }

    function closeTopUpModal() {
      document.getElementById('topUpModal').classList.remove('active');
      // Sticky idempotency key preserved during modal close to prevent duplicate credits on reopen
    }

    function selectMinuteChip(mins) {
      document.getElementById('topupMinutes').value = mins;
      if (mins === 20) document.getElementById('topupAmount').value = '0';
      if (mins === 60) document.getElementById('topupAmount').value = '1200';
      if (mins === 180) document.getElementById('topupAmount').value = '3000';
      if (mins === 500) document.getElementById('topupAmount').value = '7200';

      document.querySelectorAll('.chip-item').forEach(b => b.classList.remove('active'));
      event.target.classList.add('active');
    }

    async function handleTopUpSubmit(e) {
      e.preventDefault();
      const phone = document.getElementById('topupPhone').value.trim();
      const minutes = parseInt(document.getElementById('topupMinutes').value, 10);
      const amount = parseFloat(document.getElementById('topupAmount').value) || 0;
      const notes = document.getElementById('topupNotes').value.trim();
      const btn = document.getElementById('btnSubmitTopup');

      btn.disabled = true;
      btn.innerText = 'Processing...';

      try {
        const secret = getAdminSecret();
        // Stable idempotency key per modal session:
        // Reusing the same key across retries prevents duplicate credits on network hiccups!
        let idempotencyKey = document.getElementById('topupIdempotencyKey').value;
        if (!idempotencyKey) {
          idempotencyKey = 'topup_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8);
          document.getElementById('topupIdempotencyKey').value = idempotencyKey;
        }

        const res = await fetch('/api/admin/wallet/topup', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-admin-secret': secret,
          },
          body: JSON.stringify({
            phone,
            minutes,
            amount,
            notes,
            idempotencyKey,
            adminName: 'Admin Control Room',
          }),
        });

        const data = await res.json();
        if (res.ok && data.success) {
          if (data.alreadyProcessed) {
            showToast(`Already processed: ${minutes}m previously credited (Idempotent retry).`);
          } else {
            showToast(`Success! ${minutes} minutes credited. New balance: ${data.wallet ? data.wallet.balanceMinutes : 'Updated'}m`);
          }
          document.getElementById('topupIdempotencyKey').value = '';
          closeTopUpModal();
          fetchDashboardData();
        } else {
          showToast(`Failed: ${data.error || 'Top-up failed'}`, true);
        }
      } catch (err) {
        showToast(`Error: ${err.message}`, true);
      } finally {
        btn.disabled = false;
        btn.innerText = 'Confirm & Credit Minutes';
      }
    }

    function openEditGatewaysModal() {
      document.getElementById('egBkash').value = (document.getElementById('gwBkash').innerText || '').trim();
      document.getElementById('egNagad').value = (document.getElementById('gwNagad').innerText || '').trim();
      document.getElementById('egBinance').value = (document.getElementById('gwBinance').innerText || '').trim();
      document.getElementById('egTrc20').value = (document.getElementById('gwTrc20').innerText || '').trim();
      document.getElementById('egBep20').value = (document.getElementById('gwBep20').innerText || '').trim();
      document.getElementById('editGatewaysModal').classList.add('active');
    }

    function closeEditGatewaysModal() {
      document.getElementById('editGatewaysModal').classList.remove('active');
    }

    async function handleEditGatewaysSubmit(e) {
      e.preventDefault();
      const btn = document.getElementById('btnSubmitGateways');
      const oldText = btn.innerText;
      btn.innerText = 'Saving...';
      btn.disabled = true;

      const payload = {
        bkashNumber: document.getElementById('egBkash').value.trim(),
        nagadNumber: document.getElementById('egNagad').value.trim(),
        binancePayId: document.getElementById('egBinance').value.trim(),
        cryptoUsdtTrc20: document.getElementById('egTrc20').value.trim(),
        cryptoUsdtBep20: document.getElementById('egBep20').value.trim(),
      };

      const secret = getAdminSecret();
      try {
        const res = await fetch('/api/admin/deposit-gateways', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-admin-secret': secret,
          },
          body: JSON.stringify(payload),
        });

        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Failed to update gateways');

        showToast('✅ Deposit gateway configuration updated and saved!');
        closeEditGatewaysModal();
        if (data.depositInfo) {
          if (data.depositInfo.bkash?.number) document.getElementById('gwBkash').innerText = data.depositInfo.bkash.number;
          if (data.depositInfo.nagad?.number) document.getElementById('gwNagad').innerText = data.depositInfo.nagad.number;
          if (data.depositInfo.binancePay?.payId) document.getElementById('gwBinance').innerText = data.depositInfo.binancePay.payId;
          if (data.depositInfo.cryptoUsdt?.trc20?.address) document.getElementById('gwTrc20').innerText = data.depositInfo.cryptoUsdt.trc20.address;
          if (data.depositInfo.cryptoUsdt?.bep20?.address) document.getElementById('gwBep20').innerText = data.depositInfo.cryptoUsdt.bep20.address;
        }
      } catch (err) {
        showToast('❌ Error: ' + err.message, true);
        alert('Error saving gateways: ' + err.message);
      } finally {
        btn.innerText = oldText;
        btn.disabled = false;
      }
    }
    async function runPaymentPiiMigration() {
      const btn = document.getElementById('btnMigratePaymentPii');
      if (!confirm('Are you sure you want to run the User Payment PII Isolation Migration? This will scan all users, migrate legacy payment details to users/{id}/wallet/payment_settings, and scrub them from public user docs.')) {
        return;
      }
      const oldText = btn.innerHTML;
      btn.innerHTML = '<span>⏳ Running PII Migration...</span>';
      btn.disabled = true;

      try {
        const secret = getAdminSecret();
        const res = await fetch('/api/admin/migrate-user-payment-pii', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-admin-secret': secret,
          },
        });

        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Migration failed');

        showToast(`✅ PII Migration: Scanned ${data.scannedUsers}, Migrated ${data.migratedUsers}, Scrubbed ${data.scrubbedUsers}`);
        alert(`Migration Successful!\n\nScanned Users: ${data.scannedUsers}\nMigrated to Subcollection: ${data.migratedUsers}\nScrubbed Public Documents: ${data.scrubbedUsers}\nErrors: ${data.errors ? data.errors.length : 0}`);
      } catch (err) {
        showToast('❌ PII Migration Error: ' + err.message, true);
        alert('PII Migration Error: ' + err.message);
      } finally {
        btn.innerHTML = oldText;
        btn.disabled = false;
      }
    }

    async function runPurgeExpiredMessages() {
      const btn = document.getElementById('btnPurgeExpired');
      if (!confirm('Are you sure you want to purge all expired disappearing messages across all chats?')) {
        return;
      }
      const oldText = btn.innerHTML;
      btn.innerHTML = '<span>⚡ Purging Expired Messages...</span>';
      btn.disabled = true;

      try {
        const secret = getAdminSecret();
        const res = await fetch('/api/admin/purge-expired-messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-admin-secret': secret,
          },
        });

        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Purge failed');

        showToast(`✅ Expired Messages Purged! Deleted: ${data.purgedCount || 0} message(s)`);
        alert(`Purge Complete!\n\nDeleted Expired Messages: ${data.purgedCount || 0}\nTimestamp: ${data.purgedAt || new Date().toISOString()}`);
      } catch (err) {
        showToast('❌ Purge Error: ' + err.message, true);
        alert('Purge Error: ' + err.message);
      } finally {
        btn.innerHTML = oldText;
        btn.disabled = false;
      }
    }

/* ---- next script block ---- */

/* ============================================================
   Livocal Admin — Phase 2 UI enhancements (additive only)
   No backend/functionality changes. Wraps existing globals.
   ============================================================ */
(function () {
  'use strict';

  var TAB_ORDER = ['overview', 'payments', 'wallets', 'p2p', 'recharges', 'ledger', 'gateways'];
  var currentTab = 'payments';

  function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1); }

  /* ---------- Theme ---------- */
  window.toggleAdminTheme = function () {
    var html = document.documentElement;
    var next = html.getAttribute('data-theme') === 'light' ? '' : 'light';
    if (next) html.setAttribute('data-theme', next); else html.removeAttribute('data-theme');
    try { localStorage.setItem('livocal-admin-theme', next || 'dark'); } catch (e) {}
    syncThemeUI();
  };
  function syncThemeUI() {
    var light = document.documentElement.getAttribute('data-theme') === 'light';
    var icon = document.getElementById('sideThemeIcon');
    var label = document.getElementById('sideThemeLabel');
    var hbtn = document.getElementById('themeBtnHeader');
    if (icon) icon.textContent = light ? '☀️' : '🌙';
    if (label) label.textContent = light ? 'Dark mode' : 'Light mode';
    if (hbtn) hbtn.textContent = light ? '☀️' : '🌙';
  }

  /* ---------- Sidebar collapse + density ---------- */
  window.toggleSideCollapse = function () {
    document.body.classList.toggle('side-collapsed');
    try { localStorage.setItem('livocal-admin-side', document.body.classList.contains('side-collapsed') ? '1' : '0'); } catch (e) {}
  };
  window.toggleDensity = function () {
    document.body.classList.toggle('density-compact');
    var on = document.body.classList.contains('density-compact');
    var label = document.getElementById('sideDensityLabel');
    if (label) label.textContent = on ? 'Comfortable tables' : 'Compact tables';
    try { localStorage.setItem('livocal-admin-density', on ? '1' : '0'); } catch (e) {}
  };
  try {
    if (localStorage.getItem('livocal-admin-side') === '1') document.body.classList.add('side-collapsed');
    if (localStorage.getItem('livocal-admin-density') === '1') {
      document.body.classList.add('density-compact');
      var dl = document.getElementById('sideDensityLabel');
      if (dl) dl.textContent = 'Comfortable tables';
    }
  } catch (e) {}
  syncThemeUI();

  /* ---------- switchTab wrapper: direction + sidebar + overview ---------- */
  if (typeof window.switchTab === 'function') {
    var _origSwitchTab = window.switchTab;
    window.switchTab = function (tabId, opts) {
      var main = document.querySelector('main');
      var newIdx = TAB_ORDER.indexOf(tabId);
      var oldIdx = TAB_ORDER.indexOf(currentTab);
      if (main && newIdx > -1 && oldIdx > -1 && newIdx !== oldIdx && !(opts && opts.noAnim)) {
        main.classList.remove('slide-l', 'slide-r');
        void main.offsetWidth;
        main.classList.add(newIdx > oldIdx ? 'slide-l' : 'slide-r');
      }
      _origSwitchTab(tabId);
      currentTab = tabId;
      document.querySelectorAll('.side-nav-item').forEach(function (b) { b.classList.remove('active'); });
      var sb = document.getElementById('sideNav' + cap(tabId));
      if (sb) sb.classList.add('active');
      if (tabId === 'overview') {
        var mb = document.getElementById('mobNavOverview');
        if (mb) mb.classList.add('active');
      }
    };
  }

  /* ---------- Sidebar badge mirroring ---------- */
  function mirrorBadge(srcId, dstId) {
    var src = document.getElementById(srcId);
    var dst = document.getElementById(dstId);
    if (!src || !dst) return;
    function sync() {
      dst.textContent = src.textContent;
      dst.style.display = src.style.display;
    }
    sync();
    new MutationObserver(sync).observe(src, { childList: true, characterData: true, subtree: true, attributes: true, attributeFilter: ['style'] });
  }
  ['pendingPaymentsBadge', 'mobBadgePayments'].forEach(function (id) { mirrorBadge(id, 'sideBadgePayments'); });
  ['p2pCountBadge', 'mobBadgeP2P'].forEach(function (id) { mirrorBadge(id, 'sideBadgeP2P'); });

  /* ---------- KPI count-up ---------- */
  function parseKpi(text) {
    var m = /^([^0-9\-]*?)(-?[0-9][0-9,]*\.?[0-9]*)(.*)$/.exec(text.trim());
    if (!m) return null;
    return { prefix: m[1], value: parseFloat(m[2].replace(/,/g, '')), suffix: m[3], decimals: (m[2].split('.')[1] || '').length };
  }
  function animateKpi(el, from, to, prefix, suffix, decimals) {
    if (el._kpiRaf) cancelAnimationFrame(el._kpiRaf);
    var start = null, dur = 750;
    function fmt(v) {
      return prefix + (decimals ? v.toFixed(decimals) : Math.round(v).toLocaleString('en-US')) + suffix;
    }
    function step(ts) {
      if (!start) start = ts;
      var p = Math.min(1, (ts - start) / dur);
      var eased = 1 - Math.pow(1 - p, 3);
      el.textContent = fmt(from + (to - from) * eased);
      if (p < 1) el._kpiRaf = requestAnimationFrame(step);
      else { el.textContent = fmt(to); el._kpiRaf = null; }
    }
    el._kpiRaf = requestAnimationFrame(step);
  }
  var kpiObserver = new MutationObserver(function (mutations) {
    mutations.forEach(function (mu) {
      var el = mu.target;
      if (!el.classList || !el.classList.contains('kpi-value')) return;
      var parsed = parseKpi(el.textContent);
      if (!parsed || !isFinite(parsed.value)) return;
      var prev = el._kpiPrev;
      el._kpiPrev = parsed.value;
      if (prev === undefined || prev === parsed.value) return;
      animateKpi(el, prev, parsed.value, parsed.prefix, parsed.suffix, parsed.decimals);
    });
  });
  document.querySelectorAll('.kpi-value').forEach(function (el) {
    var p = parseKpi(el.textContent);
    el._kpiPrev = p ? p.value : 0;
    kpiObserver.observe(el, { childList: true, characterData: true, subtree: true });
  });

  /* ---------- Overview charts (real data only) ---------- */
  var ledgerCache = [];
  function esc(s) { return (window.escapeHtml || function (x) { return String(x); })(s == null ? '' : s); }

  function renderOverviewCharts() {
    renderRevenueBars();
    renderActivity();
    renderDonut();
  }

  function renderRevenueBars() {
    var box = document.getElementById('ovRevenueChart');
    if (!box) return;
    var days = [];
    var now = new Date();
    for (var i = 13; i >= 0; i--) {
      var d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      days.push({ key: d.toISOString().slice(0, 10), label: d.getDate(), total: 0 });
    }
    var map = {};
    days.forEach(function (d) { map[d.key] = d; });
    (ledgerCache || []).forEach(function (r) {
      if (!r.timestamp) return;
      var k = new Date(r.timestamp).toISOString().slice(0, 10);
      if (map[k]) map[k].total += Number(r.retailRateBdt) || 0;
    });
    var max = Math.max.apply(null, days.map(function (d) { return d.total; }).concat([1]));
    var hasData = days.some(function (d) { return d.total > 0; });
    if (!hasData) {
      box.innerHTML = '<div class="ov-empty">📭 No billed calls in the last 14 days.</div>';
      return;
    }
    box.innerHTML = days.map(function (d, idx) {
      var h = Math.max(4, Math.round((d.total / max) * 100));
      var val = d.total >= 1000 ? (d.total / 1000).toFixed(1) + 'k' : Math.round(d.total);
      return '<div class="ov-bar-col" title="৳' + Math.round(d.total).toLocaleString() + '">' +
        '<span class="ov-bar-val">৳' + val + '</span>' +
        '<div class="ov-bar" style="height:' + h + '%;animation-delay:' + (idx * 0.04) + 's"></div>' +
        '<span class="ov-bar-day">' + d.label + '</span></div>';
    }).join('');
  }

  function renderActivity() {
    var box = document.getElementById('ovActivity');
    if (!box) return;
    var recs = (ledgerCache || []).slice(-6).reverse();
    if (!recs.length) {
      box.innerHTML = '<div class="ov-empty">📭 No recent call activity.</div>';
      return;
    }
    box.innerHTML = recs.map(function (r, idx) {
      var caller = esc((r.callerId || '-').toString().substring(0, 12));
      var callee = esc((r.calleeId || '-').toString().substring(0, 12));
      var t = r.timestamp ? new Date(r.timestamp).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '';
      var profit = Number(r.netProfitBdt) || 0;
      return '<div class="ov-act" style="animation-delay:' + (idx * 0.06) + 's">' +
        '<span class="ov-act-ico">📞</span>' +
        '<div class="ov-act-main"><b>' + caller + ' → ' + callee + '</b><span>' + esc(t) + ' · Min #' + (Number(r.minuteIndex) || 1) + '</span></div>' +
        '<span class="ov-act-profit">+৳' + profit.toFixed(1) + '</span></div>';
    }).join('');
  }

  function numFromEl(id) {
    var el = document.getElementById(id);
    if (!el) return 0;
    var p = parseKpi(el.textContent);
    return p && isFinite(p.value) ? p.value : 0;
  }
  function renderDonut() {
    var profitEl = document.getElementById('ovDonutProfit');
    if (!profitEl) return;
    var profit = numFromEl('kpiProfit');
    var cost = numFromEl('kpiGeminiCost');
    var total = profit + cost;
    if (total <= 0) return;
    var pct = profit / total;
    var C = 301.6;
    profitEl.setAttribute('stroke-dasharray', (pct * C).toFixed(1) + ' ' + C.toFixed(1));
    profitEl.setAttribute('stroke', pct >= 0.5 ? '#34d399' : '#fbbf24');
    document.getElementById('ovDonutPct').textContent = Math.round(pct * 100) + '%';
    document.getElementById('ovLegendProfit').textContent = '৳' + Math.round(profit).toLocaleString();
    document.getElementById('ovLegendCost').textContent = '৳' + Math.round(cost).toLocaleString();
  }

  /* ---------- Wrap data renders ---------- */
  if (typeof window.renderLedgerTable === 'function') {
    var _rlt = window.renderLedgerTable;
    window.renderLedgerTable = function (records) {
      ledgerCache = records || [];
      var out = _rlt(records);
      renderRevenueBars();
      renderActivity();
      return out;
    };
  }

  function labelTables() {
    document.querySelectorAll('.table-responsive table').forEach(function (table) {
      var heads = Array.prototype.map.call(table.querySelectorAll('thead th'), function (th) { return th.innerText.trim(); });
      if (!heads.length) return;
      table.querySelectorAll('tbody tr').forEach(function (tr) {
        Array.prototype.forEach.call(tr.querySelectorAll('td'), function (td, i) {
          if (heads[i]) td.setAttribute('data-label', heads[i]);
        });
      });
    });
  }

  if (typeof window.fetchDashboardData === 'function') {
    var _fdd = window.fetchDashboardData;
    window.fetchDashboardData = async function () {
      var out = await _fdd();
      try { labelTables(); renderDonut(); } catch (e) {}
      return out;
    };
  }

  /* ---------- Toast stack upgrade ---------- */
  function ensureStack() {
    var s = document.getElementById('toastStack');
    if (!s) {
      s = document.createElement('div');
      s.id = 'toastStack';
      document.body.appendChild(s);
    }
    return s;
  }
  if (typeof window.showToast === 'function') {
    window.showToast = function (msg, isError) {
      var stack = ensureStack();
      var el = document.createElement('div');
      el.className = 'toast-item' + (isError ? ' err' : '');
      var txt = document.createElement('div');
      txt.innerText = msg;
      var bar = document.createElement('div');
      bar.className = 'toast-progress';
      el.appendChild(txt);
      el.appendChild(bar);
      el.onclick = function () { el.remove(); };
      stack.appendChild(el);
      while (stack.children.length > 4) stack.firstChild.remove();
      setTimeout(function () {
        el.classList.add('leaving');
        setTimeout(function () { el.remove(); }, 320);
      }, 4000);
    };
  }

  /* ---------- Command palette ---------- */
  var PALETTE_ITEMS = [
    { group: 'Tabs', icon: '🏠', label: 'Overview dashboard', hint: 'tab', run: function () { switchTab('overview'); } },
    { group: 'Tabs', icon: '🔔', label: 'Pending verifications', hint: 'tab', run: function () { switchTab('payments'); } },
    { group: 'Tabs', icon: '👥', label: 'Freelancer wallets', hint: 'tab', run: function () { switchTab('wallets'); } },
    { group: 'Tabs', icon: '🤝', label: 'In-chat P2P', hint: 'tab', run: function () { switchTab('p2p'); } },
    { group: 'Tabs', icon: '💳', label: 'Recharge ledger', hint: 'tab', run: function () { switchTab('recharges'); } },
    { group: 'Tabs', icon: '📊', label: 'Call billing ledger', hint: 'tab', run: function () { switchTab('ledger'); } },
    { group: 'Tabs', icon: '🏦', label: 'Deposit gateways', hint: 'tab', run: function () { switchTab('gateways'); } },
    { group: 'Tabs', icon: '👥', label: 'User directory', hint: 'tab', run: function () { switchTab('users'); } },
    { group: 'Tabs', icon: '🚩', label: 'User reports', hint: 'tab', run: function () { switchTab('reports'); } },
    { group: 'Tabs', icon: '💚', label: 'System health', hint: 'tab', run: function () { switchTab('health'); } },
    { group: 'Tabs', icon: '🧾', label: 'Admin audit log', hint: 'tab', run: function () { switchTab('audit'); } },
    { group: 'Actions', icon: '⚙️', label: 'Configure deposit gateways', hint: 'action', run: function () { if (window.openEditGatewaysModal) openEditGatewaysModal(); } },
    { group: 'Actions', icon: '➕', label: 'Credit minutes (quick top-up)', hint: 'action', run: function () { if (window.openTopUpModal) openTopUpModal(); } },
    { group: 'Actions', icon: '🔄', label: 'Refresh dashboard data', hint: 'action', run: function () { if (window.fetchDashboardData) fetchDashboardData(); } },
    { group: 'Actions', icon: '🌙', label: 'Toggle light / dark theme', hint: 'action', run: function () { toggleAdminTheme(); } },
    { group: 'Actions', icon: '📏', label: 'Toggle compact tables', hint: 'action', run: function () { toggleDensity(); } }
  ];
  var palIndex = 0, palFiltered = PALETTE_ITEMS.slice();

  window.openCmdPalette = function () {
    document.getElementById('cmdPaletteBackdrop').classList.add('open');
    var input = document.getElementById('cmdPaletteInput');
    input.value = '';
    renderPalette('');
    setTimeout(function () { input.focus(); }, 60);
  };
  window.closeCmdPalette = function () {
    document.getElementById('cmdPaletteBackdrop').classList.remove('open');
  };
  function renderPalette(q) {
    q = (q || '').toLowerCase();
    palFiltered = PALETTE_ITEMS.filter(function (it) { return it.label.toLowerCase().indexOf(q) > -1; });
    palIndex = 0;
    var list = document.getElementById('cmdPaletteList');
    var html = '', lastGroup = '';
    palFiltered.forEach(function (it, i) {
      if (it.group !== lastGroup) { html += '<div class="cmd-group">' + it.group + '</div>'; lastGroup = it.group; }
      html += '<button class="cmd-item' + (i === 0 ? ' selected' : '') + '" data-idx="' + i + '">' +
        '<span class="cmd-ico">' + it.icon + '</span>' + esc(it.label) + '<small>' + it.hint + '</small></button>';
    });
    list.innerHTML = html || '<div class="ov-empty">No matches.</div>';
    Array.prototype.forEach.call(list.querySelectorAll('.cmd-item'), function (btn) {
      btn.onclick = function () { activatePalette(parseInt(btn.getAttribute('data-idx'), 10)); };
      btn.onmousemove = function () { selectPalette(parseInt(btn.getAttribute('data-idx'), 10)); };
    });
  }
  function selectPalette(i) {
    var items = document.querySelectorAll('#cmdPaletteList .cmd-item');
    items.forEach(function (b) { b.classList.remove('selected'); });
    if (items[i]) {
      items[i].classList.add('selected');
      items[i].scrollIntoView({ block: 'nearest' });
      palIndex = i;
    }
  }
  function activatePalette(i) {
    var it = palFiltered[i];
    closeCmdPalette();
    if (it) { try { it.run(); } catch (e) {} }
  }
  document.addEventListener('keydown', function (e) {
    var open = document.getElementById('cmdPaletteBackdrop').classList.contains('open');
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      open ? closeCmdPalette() : openCmdPalette();
      return;
    }
    if (!open) return;
    if (e.key === 'Escape') closeCmdPalette();
    else if (e.key === 'ArrowDown') { e.preventDefault(); selectPalette(Math.min(palFiltered.length - 1, palIndex + 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); selectPalette(Math.max(0, palIndex - 1)); }
    else if (e.key === 'Enter') { activatePalette(palIndex); }
  });
  document.getElementById('cmdPaletteInput').addEventListener('input', function (e) { renderPalette(e.target.value); });

  /* ---------- Swipe between tabs (mobile) ---------- */
  var touchX = null, touchY = null;
  var mainEl = document.querySelector('main');
  if (mainEl) {
    mainEl.addEventListener('touchstart', function (e) {
      if (e.touches.length !== 1) return;
      touchX = e.touches[0].clientX;
      touchY = e.touches[0].clientY;
    }, { passive: true });
    mainEl.addEventListener('touchend', function (e) {
      if (touchX === null) return;
      var dx = e.changedTouches[0].clientX - touchX;
      var dy = e.changedTouches[0].clientY - touchY;
      touchX = null;
      if (document.querySelector('.modal-backdrop.active')) return;
      if (document.getElementById('cmdPaletteBackdrop').classList.contains('open')) return;
      if (Math.abs(dx) > 70 && Math.abs(dx) > Math.abs(dy) * 1.4) {
        var idx = TAB_ORDER.indexOf(currentTab);
        var next = dx < 0 ? Math.min(TAB_ORDER.length - 1, idx + 1) : Math.max(0, idx - 1);
        if (next !== idx) switchTab(TAB_ORDER[next]);
      }
    }, { passive: true });
  }

  /* ---------- Overview date line ---------- */
  var dl = document.getElementById('ovDateLine');
  if (dl) {
    dl.textContent = new Date().toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }) + ' — realtime SaaS pulse';
  }

  /* ---------- Initial table labels ---------- */
  labelTables();
})();

/* ---- next script block ---- */

(function () {
        'use strict';

        function adminHeaders() {
          var secret = (typeof getAdminSecret === 'function') ? getAdminSecret() : '';
          return secret ? { 'x-admin-secret': secret } : {};
        }

        async function adminGet(path) {
          var res = await fetch(path, { headers: adminHeaders() });
          if (!res.ok) throw new Error('HTTP ' + res.status);
          return res.json();
        }

        function esc(v) {
          return String(v == null ? '' : v)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
        }

        function timeAgo(value) {
          if (!value) return '—';
          var d = (typeof value === 'number') ? new Date(value)
            : new Date(String(value).replace(' ', 'T'));
          if (isNaN(d.getTime())) return String(value);
          var mins = Math.round((Date.now() - d.getTime()) / 60000);
          if (mins < 1) return 'just now';
          if (mins < 60) return mins + 'm ago';
          if (mins < 1440) return Math.round(mins / 60) + 'h ago';
          return Math.round(mins / 1440) + 'd ago';
        }

        function downloadCsv(filename, rows) {          var csv = rows.map(function (row) {
            return row.map(function (cell) {
              var s = String(cell == null ? '' : cell).replace(/"/g, '""');
              return '"' + s + '"';
            }).join(',');
          }).join('\r\n');
          var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
          var url = URL.createObjectURL(blob);
          var a = document.createElement('a');
          a.href = url;
          a.download = filename;
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        }

        /* ---------------- Users ---------------- */
        var usersCache = [];
        var usersTimer = null;
        var usersLimit = 60;

        window.loadMoreUsers = function () {
          usersLimit = Math.min(usersLimit + 60, 200);
          window.loadUsers();
        };

        window.debouncedLoadUsers = function () {
          usersLimit = 60;
          clearTimeout(usersTimer);
          usersTimer = setTimeout(function () { window.loadUsers(); }, 300);
        };

        window.loadUsers = async function () {
          var input = document.getElementById('userSearchInput');
          var q = input ? input.value.trim() : '';
          var body = document.getElementById('usersTableBody');
          var moreBtn = document.getElementById('usersLoadMoreBtn');
          if (!body) return;
          body.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:26px;color:var(--text-muted)">Loading users…</td></tr>';
          try {
            var data = await adminGet('/api/admin/users?q=' + encodeURIComponent(q) + '&limit=' + usersLimit);
            usersCache = data.users || [];
            if (moreBtn) {
              moreBtn.style.display =
                (data.total || 0) > usersCache.length ? 'inline-flex' : 'none';
            }
            if (!usersCache.length) {
              body.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:26px;color:var(--text-muted)">No users matched.</td></tr>';
              return;
            }
            body.innerHTML = usersCache.map(function (u) {
              var presence = (u.activityStatus || 'offline').toLowerCase();
              var tone = presence === 'online' ? 'ok' : 'neutral';
              return '<tr>' +
                '<td><b>' + esc(u.name || '(no name)') + '</b></td>' +
                '<td class="mono">' + esc(u.id) + '</td>' +
                '<td>' + esc(u.phoneMasked || '—') + '</td>' +
                '<td>' + esc(u.spokenLanguage || '—') + '</td>' +
                '<td><span class="status-pill ' + tone + '">' + esc(presence) + '</span></td>' +
                '<td><button class="btn btn-secondary" onclick="viewUser(\'' + esc(u.id) + '\')">Open</button></td>' +
                '</tr>';
            }).join('');
          } catch (err) {
            body.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:26px;color:#f87171">Could not load users: ' + esc(err.message) + '</td></tr>';
          }
        };

        window.exportUsersCsv = function () {
          if (!usersCache.length) return;
          var rows = [['Name', 'UID', 'Phone', 'Language', 'Presence']];
          usersCache.forEach(function (u) {
            rows.push([u.name, u.id, u.phoneMasked, u.spokenLanguage, u.activityStatus]);
          });
          downloadCsv('livocal-users.csv', rows);
        };

        /** Exports the first table rendered inside a tab (wallets, ledger, …). */
        window.exportTabCsv = function (tabId, filename) {
          var tab = document.getElementById('tab-' + tabId);
          var table = tab ? tab.querySelector('table') : null;
          if (!table) return;
          var rows = [];
          var headCells = table.querySelectorAll('thead th');
          if (headCells.length) {
            rows.push(Array.prototype.map.call(headCells, function (th) {
              return th.innerText.trim();
            }));
          }
          table.querySelectorAll('tbody tr').forEach(function (tr) {
            var cells = Array.prototype.map.call(tr.querySelectorAll('td'), function (td) {
              return td.innerText.trim().replace(/\s+/g, ' ');
            });
            if (cells.length) rows.push(cells);
          });
          downloadCsv(filename, rows);
        };

        window.viewUser = async function (uid) {
          var card = document.getElementById('userDetailCard');
          var body = document.getElementById('userDetailBody');
          if (!card || !body) return;
          card.style.display = 'block';
          document.getElementById('userDetailTitle').textContent = 'Loading…';
          document.getElementById('userDetailSub').textContent = uid;
          body.innerHTML = '<div style="padding:20px;color:var(--text-muted)">Loading profile…</div>';
          try {
            var data = await adminGet('/api/admin/users/' + encodeURIComponent(uid));
            var u = data.user || {};
            var w = data.wallet || {};
            document.getElementById('userDetailTitle').textContent = u.name || '(no name)';
            document.getElementById('userDetailSub').textContent = u.id;

            var walletRows = Object.keys(w).slice(0, 12).map(function (k) {
              return '<tr><td style="color:var(--text-muted)">' + esc(k) + '</td><td>' + esc(w[k]) + '</td></tr>';
            }).join('') || '<tr><td colspan="2" style="color:var(--text-muted)">No wallet document.</td></tr>';

            var callRows = (data.calls || []).map(function (c) {
              return '<tr><td>' + esc((c.callerId || '').slice(0, 10)) + '…</td><td>' + esc(c.status) + '</td><td>' + esc(c.durationSeconds) + 's</td><td>' + esc(timeAgo(c.createdAt)) + '</td></tr>';
            }).join('') || '<tr><td colspan="4" style="color:var(--text-muted)">No calls found.</td></tr>';

            var ledgerRows = (data.ledger || []).map(function (l) {
              return '<tr><td>' + esc(l.minutes) + ' min</td><td>' + esc(l.cost) + '</td><td>' + esc(timeAgo(l.at)) + '</td></tr>';
            }).join('') || '<tr><td colspan="3" style="color:var(--text-muted)">No billing rows.</td></tr>';

            body.innerHTML =
              '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:16px;">' +
                '<div><h3 style="margin:0 0 8px;font-size:13px;color:var(--text-muted);text-transform:uppercase">Wallet</h3>' +
                  '<div class="table-wrap"><table><tbody>' + walletRows + '</tbody></table></div></div>' +
                '<div><h3 style="margin:0 0 8px;font-size:13px;color:var(--text-muted);text-transform:uppercase">Recent calls</h3>' +
                  '<div class="table-wrap"><table><thead><tr><th>Peer</th><th>Status</th><th>Duration</th><th>When</th></tr></thead><tbody>' + callRows + '</tbody></table></div></div>' +
                '<div><h3 style="margin:0 0 8px;font-size:13px;color:var(--text-muted);text-transform:uppercase">Billing ledger</h3>' +
                  '<div class="table-wrap"><table><thead><tr><th>Minutes</th><th>Cost</th><th>When</th></tr></thead><tbody>' + ledgerRows + '</tbody></table></div></div>' +
              '</div>';
          } catch (err) {
            body.innerHTML = '<div style="padding:20px;color:#f87171">Could not load profile: ' + esc(err.message) + '</div>';
          }
        };

        window.hideUserDetail = function () {
          var card = document.getElementById('userDetailCard');
          if (card) card.style.display = 'none';
        };

        /* ---------------- Reports ---------------- */
        window.loadReports = async function () {
          var body = document.getElementById('reportsTableBody');
          if (!body) return;
          body.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:26px;color:var(--text-muted)">Loading reports…</td></tr>';
          try {
            var data = await adminGet('/api/admin/reports?limit=100');
            var reports = data.reports || [];
            if (!reports.length) {
              body.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:26px;color:var(--text-muted)">No reports yet.</td></tr>';
              return;
            }
            body.innerHTML = reports.map(function (r) {
              var tone = r.status === 'pending_review'
                ? 'warn' : (r.status === 'resolved' ? 'ok' : 'neutral');
              return '<tr>' +
                '<td class="mono">' + esc(r.reportedUserId || r.targetId || r.targetUserId || '—') + '</td>' +
                '<td class="mono">' + esc(r.reporterId || '—') + '</td>' +
                '<td>' + esc(r.reason || r.category || r.message || '—') + '</td>' +
                '<td><span class="status-pill ' + tone + '">' + esc(r.status || '—') + '</span></td>' +
                '<td>' + esc(timeAgo(r.timestamp || r.createdAt)) + '</td>' +
                '<td><span class="table-actions">' +
                  '<button class="btn btn-secondary" onclick="reviewReport(\'' + esc(r.id) + '\',\'resolved\')">Resolve</button>' +
                  '<button class="btn btn-secondary" onclick="reviewReport(\'' + esc(r.id) + '\',\'dismissed\')">Dismiss</button>' +
                '</span></td></tr>';
            }).join('');
          } catch (err) {
            body.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:26px;color:#f87171">Could not load reports: ' + esc(err.message) + '</td></tr>';
          }
        };

        window.reviewReport = async function (id, status) {
          try {
            var res = await fetch('/api/admin/reports/' + encodeURIComponent(id) + '/action', {
              method: 'POST',
              headers: Object.assign({ 'Content-Type': 'application/json' }, adminHeaders()),
              body: JSON.stringify({ status: status }),
            });
            if (!res.ok) throw new Error('HTTP ' + res.status);
            window.loadReports();
          } catch (err) {
            alert('Could not update report: ' + err.message);
          }
        };

        /* ---------------- Health ---------------- */
        window.loadHealth = async function () {
          var grid = document.getElementById('healthGrid');
          var raw = document.getElementById('healthRaw');
          if (!grid) return;
          grid.innerHTML = '<div style="padding:16px;color:var(--text-muted)">Checking services…</div>';
          try {
            var res = await fetch('/health');
            var h = await res.json();
            var cards = [
              ['Relay', h.status === 'ok' ? 'ONLINE' : 'DOWN', h.status === 'ok'],
              ['Gemini key', h.hasApiKey ? 'CONFIGURED' : 'MISSING', !!h.hasApiKey],
              ['TURN', h.hasTurn ? (h.turnProvider || 'configured') : 'NOT SET', !!h.hasTurn],
              ['App Check', h.appCheckEnforced ? 'ENFORCED' : 'OFF', !!h.appCheckEnforced],
              ['Live model', h.liveModel || '—', true],
              ['Text model', h.textModel || '—', true],
              ['Uptime', (h.uptime || 0) + 's', true],
            ];
            grid.innerHTML = cards.map(function (c) {
              var tone = c[2] ? 'ok' : 'warn';
              return '<div class="ops-kpi">' +
                '<div class="kpi-label">' + esc(c[0]) + '</div>' +
                '<div class="kpi-value"><span class="status-pill ' + tone + '">' + esc(c[1]) + '</span></div>' +
                '</div>';
            }).join('');
            if (raw) raw.textContent = JSON.stringify(h);
          } catch (err) {
            grid.innerHTML = '<div style="padding:16px;color:#f87171">Health check failed: ' + esc(err.message) + '</div>';
          }
        };

        window.loadAudit = async function () {
          var body = document.getElementById('auditTableBody');
          if (!body) return;
          body.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:26px;color:var(--text-muted)">Loading audit trail…</td></tr>';
          try {
            var data = await adminGet('/api/admin/audit?limit=200');
            var entries = data.entries || [];
            if (!entries.length) {
              body.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:26px;color:var(--text-muted)">No privileged actions recorded yet.</td></tr>';
              return;
            }
            body.innerHTML = entries.map(function (e) {
              var tone = e.method === 'DELETE' ? 'bad' : (e.method === 'POST' ? 'warn' : 'neutral');
              return '<tr>' +
                '<td>' + esc(timeAgo(e.atMs || e.at)) + '</td>' +
                '<td><span class="status-pill ' + tone + '">' + esc(e.method || '') + '</span></td>' +
                '<td class="mono">' + esc(e.path || '') + '</td>' +
                '<td class="mono">' + esc(e.ip || '') + '</td>' +
                '<td class="muted" style="font-size:11px">' + esc((e.ua || '').slice(0, 60)) + '</td>' +
                '</tr>';
            }).join('');
          } catch (err) {
            body.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:26px;color:#f87171">Could not load audit log: ' + esc(err.message) + '</td></tr>';
          }
        };

        /* ---------------- CSV buttons on the existing financial tabs ---------- */
        function injectCsvButtons() {
          ['wallets', 'recharges', 'ledger'].forEach(function (tabId) {
            var tabEl = document.getElementById('tab-' + tabId);
            if (!tabEl) return;
            var bar = tabEl.querySelector('.card-header-bar') || tabEl.querySelector('.card-title-group');
            if (!bar || bar.querySelector('.csv-export-btn')) return;
            var btn = document.createElement('button');
            btn.className = 'btn btn-secondary csv-export-btn';
            btn.textContent = '⬇ CSV';
            btn.addEventListener('click', function () {
              window.exportTabCsv(tabId, 'livocal-' + tabId + '.csv');
            });
            bar.appendChild(btn);
          });
        }

        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', injectCsvButtons);
        } else {
          injectCsvButtons();
        }
      })();