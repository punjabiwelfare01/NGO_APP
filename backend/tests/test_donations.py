"""Donations feature: NGO payment details, submitting/reviewing donations,
and stipend config/records."""


class TestNgoPaymentDetails:
    def test_public_read_before_any_write(self, client, student_headers):
        resp = client.get("/donations/ngo-payment", headers=student_headers)
        assert resp.status_code == 200

    def test_admin_can_set_payment_details(self, client, admin_headers, student_headers):
        resp = client.put("/donations/ngo-payment", json={
            "upi_id": "trust@upi",
            "account_holder": "Punjabi Welfare Trust",
            "bank_name": "Union Bank of India",
            "account_number": "35270101011873",
            "ifsc_code": "UBIN0535273",
        }, headers=admin_headers)
        assert resp.status_code == 200, resp.text

        read_back = client.get("/donations/ngo-payment", headers=student_headers)
        assert read_back.json()["upi_id"] == "trust@upi"

    def test_student_cannot_set_payment_details(self, client, student_headers):
        resp = client.put("/donations/ngo-payment", json={"upi_id": "hijack@upi"}, headers=student_headers)
        assert resp.status_code == 403


class TestDonationLifecycle:
    def test_student_submits_donation(self, client, student_headers):
        resp = client.post("/donations", json={
            "donation_type": "money",
            "amount": 500,
            "purpose": "Education support",
        }, headers=student_headers)
        assert resp.status_code == 200, resp.text
        assert resp.json()["status"] == "pending"

    def test_student_sees_own_donations_only(self, client, student_headers, mentor_headers):
        client.post("/donations", json={"donation_type": "money", "amount": 100}, headers=student_headers)
        mine = client.get("/donations/me", headers=student_headers).json()
        assert len(mine) == 1

    def test_admin_lists_all_donations(self, client, admin_headers, student_headers):
        client.post("/donations", json={"donation_type": "money", "amount": 100}, headers=student_headers)
        resp = client.get("/donations", headers=admin_headers)
        assert resp.status_code == 200
        assert len(resp.json()) == 1

    def test_student_cannot_list_all_donations(self, client, student_headers):
        resp = client.get("/donations", headers=student_headers)
        assert resp.status_code == 403

    def test_admin_can_approve_donation(self, client, admin_headers, student_headers):
        created = client.post("/donations", json={
            "donation_type": "money", "amount": 250,
        }, headers=student_headers).json()

        resp = client.patch(
            f"/donations/{created['id']}/review",
            json={"status": "verified", "receipt_number": "RCPT-001"},
            headers=admin_headers,
        )
        assert resp.status_code == 200, resp.text
        assert resp.json()["status"] == "verified"

    def test_things_donation_does_not_require_amount(self, client, student_headers):
        resp = client.post("/donations", json={
            "donation_type": "things", "items_desc": "20 notebooks",
        }, headers=student_headers)
        assert resp.status_code == 200
        assert resp.json()["items_desc"] == "20 notebooks"


class TestStipendConfig:
    def test_admin_can_set_and_read_stipend_config(self, client, admin_headers):
        resp = client.put("/donations/stipend-config", json={
            "percentage": 10, "is_active": True, "min_donation_threshold": 100,
        }, headers=admin_headers)
        assert resp.status_code == 200, resp.text

        read_back = client.get("/donations/stipend-config", headers=admin_headers)
        assert read_back.json()["percentage"] == 10

    def test_student_cannot_read_stipend_config(self, client, student_headers):
        resp = client.get("/donations/stipend-config", headers=student_headers)
        assert resp.status_code == 403

    def test_student_sees_own_stipends_empty_initially(self, client, student_headers):
        resp = client.get("/donations/stipends/me", headers=student_headers)
        assert resp.status_code == 200
        assert resp.json() == []
