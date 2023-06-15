local QBCore = exports["qb-core"]:GetCoreObject()
local PlayerJob = {}
PlayerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

Citizen.CreateThread(function()
	while QBCore.Functions.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent("QBCore:Client:OnJobUptade")
AddEventHandler("QBCore:Client:OnJobUptade", function(job)
	PlayerData.job = job
end)

function MyInvoices()
	QBCore.Functions.TriggerCallback("okokBilling:GetInvoices", function(invoices)
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'myinvoices',
			invoices = invoices,
			VAT = Config.VATPercentage
		})			
	end)
end

function SocietyInvoices(society)
	QBCore.Functions.TriggerCallback("okokBilling:GetSocietyInvoices", function(cb, totalInvoices, totalIncome, totalUnpaid, awaitedIncome)
		if json.encode(cb) ~= '[]' then
			SetNuiFocus(true, true)
			SendNUIMessage({
				action = 'societyinvoices',
				invoices = cb,
				totalInvoices = totalInvoices,
				totalIncome = totalIncome,
				totalUnpaid = totalUnpaid,
				awaitedIncome = awaitedIncome,
				VAT = Config.VATPercentage
			})		
		else
			exports['okokNotify']:Alert("Thông Báo", "Công ty của bạn không có hóa đơn", 10000, "error")

			--exports['okokNotify']:Alert("BILLING", "Your society doesn't have invoices.", 10000, 'info')
			SetNuiFocus(false, false)
		end
	end, society)
end

function CreateInvoice(society)
	SetNuiFocus(true, true)
	SendNUIMessage({
		action = 'createinvoice',
		society = society
	})
end

RegisterCommand(Config.InvoicesCommand, function()
	local isAllowed = false
	local jobName = ""
	for k, v in pairs(Config.AllowedSocieties) do
		if v == PlayerJob.name then
			jobName = v
			isAllowed = true
		end
	end

	if Config.OnlyBossCanAccessSocietyInvoices and PlayerJob.isboss == true and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = true,
			create = true
		})
	elseif Config.OnlyBossCanAccessSocietyInvoices and PlayerJob.grade.name ~= true and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = false,
			create = true
		})
	elseif not Config.OnlyBossCanAccessSocietyInvoices and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = true,
			create = true
		})
	elseif not isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = false,
			create = false
		})
	end
end, false)

RegisterNUICallback("action", function(data, cb)
	if data.action == "close" then
		SetNuiFocus(false, false)
	elseif data.action == "payInvoice" then
		TriggerServerEvent("okokBilling:PayInvoice", data.invoice_id)
		SetNuiFocus(false, false)
	elseif data.action == "cancelInvoice" then
		TriggerServerEvent("okokBilling:CancelInvoice", data.invoice_id)
		SetNuiFocus(false, false)
	elseif data.action == "createInvoice" then
		local closestPlayer, playerDistance = QBCore.Functions.GetClosestPlayer()
		target = GetPlayerServerId(closestPlayer)
		data.target = target
		data.society = PlayerJob.name
		data.society_name = PlayerJob.label

		if closestPlayer == -1 or playerDistance > 3.0 then
			exports['okokNotify']:Alert("Hóa Đơn", "Lỗi gửi hóa đơn! Không có ai ở gần bạn.", 10000, 'error')
		else
			TriggerServerEvent("okokBilling:CreateInvoice", data)
			exports['okokNotify']:Alert("Hóa Đơn", "Hóa đơn đã gửi thành công!", 10000, 'success')
		end
		
		SetNuiFocus(false, false)
	elseif data.action == "missingInfo" then
		exports['okokNotify']:Alert("Hóa Đơn", "Điền vào tất cả các thông tin trước khi gửi hóa đơn!", 10000, 'error')
	elseif data.action == "negativeAmount" then
		exports['okokNotify']:Alert("Hóa Đơn", "Bạn điền một số dương!", 10000, 'error')
	elseif data.action == "mainMenuOpenMyInvoices" then
		MyInvoices()
	elseif data.action == "mainMenuOpenSocietyInvoices" then
		for k, v in pairs(Config.AllowedSocieties) do
			if v == PlayerJob.name then
				if Config.OnlyBossCanAccessSocietyInvoices then
					SocietyInvoices(PlayerJob.label)
				else
					exports['okokNotify']:Alert("Hóa Đơn", "Chỉ Giám đốc mới có thể truy cập hóa đơn Công ty.", 10000, 'error')
				end
			end
		end
	elseif data.action == "mainMenuOpenCreateInvoice" then
		for k, v in pairs(Config.AllowedSocieties) do
			if v == PlayerJob.name then
				CreateInvoice(PlayerJob.label)
			end
		end
	end
end)