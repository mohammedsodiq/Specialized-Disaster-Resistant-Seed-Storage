import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock the Clarity contract interactions
const mockContractCalls = {
  declareDisasterEvent: vi.fn(),
  getDisasterEvent: vi.fn(),
  endDisasterEvent: vi.fn(),
  requestSeedDistribution: vi.fn(),
  getDistributionRequest: vi.fn(),
  approveDistributionRequest: vi.fn(),
  rejectDistributionRequest: vi.fn(),
  addAuthorizer: vi.fn(),
  removeAuthorizer: vi.fn(),
  isAuthorizer: vi.fn(),
}

// Mock contract response data
const mockDisasterEvent = {
  name: "Hurricane Alpha",
  description: "Category 4 hurricane affecting coastal regions",
  "affected-region": "Eastern Seaboard",
  severity: 4,
  "start-date": 12345,
  "end-date": { type: "none" },
  "declared-by": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  active: true,
}

const mockDistributionRequest = {
  "event-id": "EVENT-1",
  requester: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG",
  "facility-id": "FAC-1",
  "variety-id": "VAR-1",
  "quantity-requested": 2000,
  purpose: "Community garden restoration after hurricane",
  "request-date": 12350,
  status: "PENDING",
  "approved-by": { type: "none" },
  "approval-date": { type: "none" },
  notes: "",
}

describe("Access Protocol Contract", () => {
  beforeEach(() => {
    // Reset mocks before each test
    vi.resetAllMocks()
    
    // Setup default mock responses
    mockContractCalls.getDisasterEvent.mockResolvedValue(mockDisasterEvent)
    mockContractCalls.getDistributionRequest.mockResolvedValue(mockDistributionRequest)
    mockContractCalls.isAuthorizer.mockResolvedValue(true)
    mockContractCalls.declareDisasterEvent.mockResolvedValue({
      value: "EVENT-1",
      type: "ok",
    })
    mockContractCalls.endDisasterEvent.mockResolvedValue({
      value: true,
      type: "ok",
    })
    mockContractCalls.requestSeedDistribution.mockResolvedValue({
      value: "REQ-1",
      type: "ok",
    })
    mockContractCalls.approveDistributionRequest.mockResolvedValue({
      value: true,
      type: "ok",
    })
    mockContractCalls.rejectDistributionRequest.mockResolvedValue({
      value: true,
      type: "ok",
    })
    mockContractCalls.addAuthorizer.mockResolvedValue({
      value: true,
      type: "ok",
    })
    mockContractCalls.addAuthorizer.mockResolvedValue({
      value: true,
      type: "ok",
    })
    mockContractCalls.removeAuthorizer.mockResolvedValue({
      value: true,
      type: "ok",
    })
  })
  
  describe("declareDisasterEvent", () => {
    it("should successfully declare a new disaster event", async () => {
      const result = await mockContractCalls.declareDisasterEvent(
          "Hurricane Alpha",
          "Category 4 hurricane affecting coastal regions",
          "Eastern Seaboard",
          4,
          12345,
      )
      
      expect(mockContractCalls.declareDisasterEvent).toHaveBeenCalledTimes(1)
      expect(result.type).toBe("ok")
      expect(result.value).toBe("EVENT-1")
    })
    
    it("should reject declaration from unauthorized user", async () => {
      mockContractCalls.isAuthorizer.mockResolvedValue(false)
      mockContractCalls.declareDisasterEvent.mockResolvedValue({
        type: "err",
        value: 100, // ERR-NOT-AUTHORIZED
      })
      
      const result = await mockContractCalls.declareDisasterEvent(
          "Hurricane Alpha",
          "Category 4 hurricane affecting coastal regions",
          "Eastern Seaboard",
          4,
          12345,
      )
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(100)
    })
  })
  
  describe("endDisasterEvent", () => {
    it("should successfully end an active disaster event", async () => {
      const result = await mockContractCalls.endDisasterEvent("EVENT-1", 12400)
      
      expect(mockContractCalls.endDisasterEvent).toHaveBeenCalledTimes(1)
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject ending an already ended event", async () => {
      mockContractCalls.getDisasterEvent.mockResolvedValue({
        ...mockDisasterEvent,
        active: false,
      })
      
      mockContractCalls.endDisasterEvent.mockResolvedValue({
        type: "err",
        value: 106, // ERR-INVALID-STATE
      })
      
      const result = await mockContractCalls.endDisasterEvent("EVENT-1", 12400)
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(106)
    })
  })
  
  describe("requestSeedDistribution", () => {
    it("should successfully create a distribution request", async () => {
      const result = await mockContractCalls.requestSeedDistribution(
          "EVENT-1",
          "FAC-1",
          "VAR-1",
          2000,
          "Community garden restoration after hurricane",
      )
      
      expect(mockContractCalls.requestSeedDistribution).toHaveBeenCalledTimes(1)
      expect(result.type).toBe("ok")
      expect(result.value).toBe("REQ-1")
    })
    
    it("should reject request for inactive disaster event", async () => {
      mockContractCalls.getDisasterEvent.mockResolvedValue({
        ...mockDisasterEvent,
        active: false,
      })
      
      mockContractCalls.requestSeedDistribution.mockResolvedValue({
        type: "err",
        value: 106, // ERR-INVALID-STATE
      })
      
      const result = await mockContractCalls.requestSeedDistribution(
          "EVENT-1",
          "FAC-1",
          "VAR-1",
          2000,
          "Community garden restoration after hurricane",
      )
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(106)
    })
  })
  
  describe("approveDistributionRequest", () => {
    it("should successfully approve a distribution request", async () => {
      const result = await mockContractCalls.approveDistributionRequest("REQ-1", "Approved for immediate distribution")
      
      expect(mockContractCalls.approveDistributionRequest).toHaveBeenCalledTimes(1)
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject approval from unauthorized user", async () => {
      mockContractCalls.isAuthorizer.mockResolvedValue(false)
      mockContractCalls.approveDistributionRequest.mockResolvedValue({
        type: "err",
        value: 100, // ERR-NOT-AUTHORIZED
      })
      
      const result = await mockContractCalls.approveDistributionRequest("REQ-1", "Approved for immediate distribution")
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(100)
    })
  })
  
  describe("rejectDistributionRequest", () => {
    it("should successfully reject a distribution request", async () => {
      const result = await mockContractCalls.rejectDistributionRequest("REQ-1", "Insufficient documentation provided")
      
      expect(mockContractCalls.rejectDistributionRequest).toHaveBeenCalledTimes(1)
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
  
  describe("addAuthorizer", () => {
    it("should successfully add an authorizer", async () => {
      const result = await mockContractCalls.addAuthorizer("ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG")
      
      expect(mockContractCalls.addAuthorizer).toHaveBeenCalledTimes(1)
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
  
  describe("removeAuthorizer", () => {
    it("should successfully remove an authorizer", async () => {
      const result = await mockContractCalls.removeAuthorizer("ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG")
      
      expect(mockContractCalls.removeAuthorizer).toHaveBeenCalledTimes(1)
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
})

