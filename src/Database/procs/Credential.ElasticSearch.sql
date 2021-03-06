USE [credFinder]
GO
--USE staging_credFinder
--GO
/****** Object:  StoredProcedure [dbo].[Credential.ElasticSearch]    Script Date: 3/8/2018 7:22:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
SELECT TOP (1000) [Id]
      ,[EntityId]
      ,[CredentialId]
      ,[Created]
  FROM [credFinder].[dbo].[Entity.Credential]
  where entityid in (29692 , 29679, 235941 , 236400 )
  or CredentialId in (48, 681, 717, 310 )
  order by 2,3


<Connections><row ConnectionTypeId="7" ConnectionType="Advanced Standing From" AssessmentId="0" AssessmentName="" CredentialId="139" CredentialName="Associate in Applied Science in Surveying Technology" LearningOpportunityId="0" LearningOpportunityName="" credOrgid="47" credOrganization="Ferris State University" asmtOrgid="0" loppOrgid="0"/></Connections>

--=====================================================

	DECLARE @RC int,@SortOrder varchar(100),@Filter varchar(5000)
	DECLARE @StartPageIndex int, @PageSize int, @TotalRows int
	--

	set @SortOrder = ''
	set @SortOrder = 'newest'
	set @SortOrder = 'id'

	-- blind search 


	set @Filter = '  (base.Id in (SELECT [RecordId]  FROM [dbo].[SearchPendingReindex] where [EntityTypeId]= 1 And [StatusId] = 1) )  '
	--set @Filter = ' len(base.QAAgentAndRoles) > 0'
	--set @Filter = '  ( base.id < 2000 )  '
	--set @Filter = ''

	set @StartPageIndex = 1
	set @PageSize = 200
	--set statistics IO on       
	EXECUTE @RC = [Credential.ElasticSearch]
			 @Filter,@SortOrder  ,@StartPageIndex  ,@PageSize, @TotalRows OUTPUT

	select 'total rows = ' + convert(varchar,@TotalRows)

	--set statistics IO off       
	--34
	--31 using xapply
	*/

/*
Description:      Credential search for elastic load
Options:

  @StartPageIndex - starting page number. 
  @PageSize - number of records on a page
  @TotalRows OUTPUT - total available rows. Used by interface to build a
custom pager
  ------------------------------------------------------
Modifications
18-01-22 mparsons - created from existing search
18-10-06 mparsons - removed [IsQARole]= 1 from QualityAssurance, so that owned and offered by can be filtered. The actual property name should also be changed now! 
*/
ALTER PROCEDURE [dbo].[Credential.ElasticSearch] 
		@Filter           varchar(5000)
		,@SortOrder       varchar(100)
		,@StartPageIndex  int
		,@PageSize        int
		,@TotalRows       int OUTPUT
As

SET NOCOUNT ON;
-- paging
DECLARE
      @first_id               int
      ,@startRow        int
      ,@debugLevel      int
      ,@SQL             varchar(5000)
      ,@OrderBy         varchar(100)
	  ,@HasSitePrivileges bit
	  ,@UsingSummaryCache bit
	  
--set @CurrentUserId = 21
Set @debugLevel = 4
set @HasSitePrivileges= 0
-- probably will never use cache for a build
--unless we should always ensure cache sources are updated before a build???
set @UsingSummaryCache = 0

if @SortOrder = 'relevance' set @SortOrder = 'base.Name '
else if @SortOrder = 'alpha' set @SortOrder = 'base.Name '
else if @SortOrder = 'id' set @SortOrder = 'base.Id '
--else if @SortOrder = 'cost_highest' set @SortOrder = 'costs.TotalCost DESC'
--else if @SortOrder = 'cost_lowest' set @SortOrder = 'costs.TotalCost'
else if @SortOrder = 'duration_shortest' set @SortOrder = 'duration.AverageMinutes '
else if @SortOrder = 'duration_longest' set @SortOrder = 'duration.AverageMinutes DESC'
else if @SortOrder = 'newest' set @SortOrder = 'base.lastUpdated Desc '
else set @SortOrder = 'base.Name '

if len(@SortOrder) > 0 
      set @OrderBy = ' Order by ' + @SortOrder
else
      set @OrderBy = ' Order by base.Name '

SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

CREATE TABLE #tempWorkTable(
	RowNumber         int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Id int,
	Title             varchar(200),
	LastUpdated			datetime,
	TotalCost [decimal](9, 2) ,
	AverageDuration int
			--,RowId	 uniqueidentifier
)

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter
     end
  
	if @UsingSummaryCache = 1 begin
		set @SQL = 'SELECT distinct base.Id, base.Name, base.lastUpdated
from [Credential.SummaryCache] b  
Inner join credential base on b.CredentialId = base.Id
inner join [Credential_Summary] cs  on cs.Id = base.Id
--not ideal, but doing a total
--left join (
--					Select ParentEntityUid, sum(isnull(TotalCost, 0)) As TotalCost from Entity_CostProfileTotal group by ParentEntityUid
--					) costs	on base.RowId = costs.ParentEntityUid 

--left join (SELECT [ParentEntityUid] ,sum([AverageMinutes]) as [AverageMinutes] 
--		FROM [dbo].[Entity_Duration_EntityAverage] group by [ParentEntityUid])  duration on base.RowId = duration.ParentEntityUid  
	'
					+ @Filter
				end
	else begin
		set @SQL = 'SELECT distinct base.Id, base.Name, base.lastUpdated
					from [Credential_Summary] base  	'
        + @Filter
		end
--, AverageMinutes 
----left join [Entity_Duration_EntityAverage] duration on base.EntityUid = duration.ParentEntityUid 
--				
        
  if charindex( 'order by', lower(@Filter) ) = 0
    set @SQL = @SQL + ' ' + @OrderBy

  print '@SQL len: '  +  convert(varchar,len(@SQL))
  print @SQL

  INSERT INTO #tempWorkTable (Id, Title, LastUpdated)
  exec (@SQL)
  --print 'rows: ' + convert(varchar, @@ROWCOUNT)
  SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Calculate the range
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

-- ================================= 

SELECT        Distinct
	RowNumber, 
	work.Id, 
	base.Name, 
	base.AlternateName,
	base.EntityUid,
	base.Description, base.SubjectWebpage,
	base.OwningAgentUid,
	base.OwningOrganizationId,
	base.OwningOrganization,
	base.OwningOrganizationCtid,
	--base.ManagingOrgId, managingOrg.Name as ManagingOrganization,
	base.EntityStateId,
	base.EffectiveDate,
	base.Version,
	base.LatestVersionUrl,
	
	base.PreviousVersion,	
	base.CTID, 
	base.CredentialRegistryId,
	base.CredentialId,
	base.availableOnlineAt,
	base.AvailabilityListing,
	base.Created, 
	base.LastUpdated, 
	e.LastUpdated As EntityLastUpdated,
	-- ======================================================
	base.EntityId,
	base.CredentialType,
	base.CredentialTypeId,
	base.CredentialTypeSchema,
	base.CredentialStatus,
	base.CredentialStatusId,
	Isnull(base.ImageUrl,'') as ImageUrl,
	base.IsAQACredential,
--	base.HasQualityAssurance,

		--creator org
	--base.CreatorOrgs,
	'' as CreatorOrgs,
	--base.OwningOrgs
	'' as OwningOrgs
	,base.AssessmentsCompetenciesCount
	,base.LearningOppsCompetenciesCount
	,base.RequiresCompetenciesCount
	--,base.QARolesCount

	,base.RequiresCount
	,base.RecommendsCount
	,base.entryConditionCount

	,base.isRequiredForCount
	,base.IsRecommendedForCount
	,0 as RenewalCount
	,base.IsAdvancedStandingForCount
	,base.AdvancedStandingFromCount
	,base.isPreparationForCount
	,base.isPreparationFromCount

	,IsNull(CommonCost.Nbr,0) As CommonCostsCount
	,IsNull(CommonCondition.Nbr,0) As CommonConditionsCount
	
	,IsNULL(costProfiles.Nbr, 0) As CostProfilesCount
	--remove these
	--,IsNULL(costs.TotalCost, 0) As TotalCostCount
	,0 as TotalCost
	,0 As TotalCostCount
	--total cost items - just for credential, AND child items
	--,Isnull(allCostProfiles.Total,0) as CostProfileCount
	,IsNULL(FinancialAid.Nbr, 0) As FinancialAidCount
	,IsNULL(EmbeddedCredentials.Nbr, 0) As EmbeddedCredentialsCount
	--targets
	,IsNULL(reqTargets.HasTargetAssessments, 0) As RequiredAssessmentsCount
	,IsNULL(reqTargets.HasTargetCredentials, 0) As RequiredCredentialsCount
	,IsNULL(reqTargets.HasLearningOpportunities, 0) As RequiredLoppCount

	,IsNULL(recommendedTargets.HasTargetAssessments, 0) As RecommendedAssessmentsCount
	,IsNULL(recommendedTargets.HasTargetCredentials, 0) As RecommendedCredentialsCount
	,IsNULL(recommendedTargets.HasLearningOpportunities, 0) As RecommendedLoppCount

	,IsNULL(processProfiles.Nbr, 0) As ProcessProfilesCount
	,IsNULL(revocationProfiles.Nbr, 0) As RevocationProfilesCount

	,IsNULL(HasOccupations.Nbr, 0) As HasOccupationsCount
	,IsNULL(HasIndustries.Nbr, 0) As HasIndustriesCount
	--,IsNULL(HasCIPs.Nbr, 0) As HasCipsCount
	--,ISNULL(CIPCounts.Nbr, 0 ) As InstructionalProgramCount
	,IsNULL(HasConditionProfile.Nbr, 0) As HasConditionProfileCount
	,IsNULL(HasDuration.Nbr, 0) As HasDurationCount

	--may add the following to the assessment_summary, or a separate view that is clearly only for use with the index build
	,(SELECT DISTINCT ConnectionTypeId ,ConnectionType  ,AssessmentId, isnull(AssessmentName,'') As AssessmentName,   CredentialId, IsNUll(CredentialName,'') As CredentialName, LearningOpportunityId,			    Isnull(LearningOpportunityName,'') As LearningOpportunityName ,credOrgid,credOrganization, asmtOrgid, asmtOrganization, loppOrgid, loppOrganization
	FROM [dbo].[Entity_ConditionProfilesConnectionsSummary]  
	WHERE EntityTypeId = 1 AND EntityBaseId = base.id  
	FOR XML RAW, ROOT('Connections')) CredentialConnections

	--this may be obsolete now - that is it should be moved to the summaries or cache?
	--18-04-11 mp - still in use ==> needed when using View, vs cache
	,isnull(connectionsCsv.Profiles,'') As ConnectionsList			--actual connection type (no credential info)
	,isnull(connectionsCsv.CredentialsList,'') As CredentialsList	--connection type, plus Id, and name of credential

	--,duration.AverageMinutes,
	--isnull(costProfiles.Total,0) as NumberOfCostProfiles,
	,isnull(duration.AverageMinutes,0) as AverageMinutes,

	--isnull(duration.FromDuration,'') as FromDuration,
	--isnull(duration.ToDuration,'') as ToDuration,
	--isnull(props.properties,'') As Properties,
	--isnull(naicsCsv.naics,'') As NaicsList,
	--isnull(naicsCsv.Others,'') As OtherIndustriesList,
	--isnull(occsCsv.Occupations,'') As OccupationsList,
	--isnull(occsCsv.Others,'') As OtherOccupationsList,
	--isnull(subjectsCsv.Subjects,'') As SubjectsList,

	isnull(badgeClaims.Total, 0) as badgeClaimsCount
	,ea.Nbr as AvailableAddresses

	,base.HasPartCount
	,base.HasPartList as HasPartsList
	,base.IsPartOfCount
	,base.IsPartOfList
	-- ======================================================
	-- For ElasticSearch
	-- Depends on Entity.SearchIndex, so the latter must be up to date!
	, (SELECT ISNULL(NULLIF(a.TextValue, ''), NULL) TextValue, a.[CodedNotation], a.CategoryId FROM [dbo].[Entity] e INNER JOIN [dbo].[Entity.SearchIndex] a ON a.EntityId = e.Id where e.EntityTypeId = 1 AND base.RowId = e.EntityUid FOR XML RAW, ROOT('TextValues')) TextValues

	--, (SELECT ISNULL(NULLIF(a.CodedNotation, ''), NULL) CodedNotation FROM [dbo].[Entity] e INNER JOIN [dbo].[Entity.SearchIndex] a ON a.EntityId = e.Id where e.EntityTypeId = 1 AND base.RowId = e.EntityUid FOR XML RAW, ROOT('CodedNotation')) CodedNotation
	
	--, STUFF((SELECT '|' + ISNULL(NULLIF(a.CodedNotation, ''), NULL) AS [text()] FROM [dbo].[Entity] e INNER JOIN [dbo].[Entity.SearchIndex] a ON a.EntityId = e.Id where e.EntityTypeId = 1 AND base.RowId = e.EntityUid FOR XML Path('')), 1,1,'') CodedNotation

	--,isnull(levelsCsv.Properties,'') As LevelsList
	--, STUFF((SELECT '|' + ISNULL(NULLIF(CAST(eps.PropertyValueId AS NVARCHAR(MAX)), ''), NULL) AS [text()] FROM [dbo].[EntityProperty_Summary] eps 
	--	where eps.EntityTypeId = 1 AND eps.CategoryId = 4 AND eps.EntityBaseId = base.Id 
	--	FOR XML Path('')), 1,1,'') AudienceLevelTypeIds

	--,isnull(typesCsv.Properties,'') As TypesList
	 --, STUFF((SELECT '|' + ISNULL(NULLIF(CAST(eps.PropertyValueId AS NVARCHAR(MAX)), ''), NULL) AS [text()] FROM [dbo].[EntityProperty_Summary] eps 
		--where eps.EntityTypeId = 1 AND eps.CategoryId = 14 AND eps.EntityBaseId = base.Id 
		--FOR XML Path('')), 1,1,'') AudienceTypeIds
 
 ,  ( SELECT DISTINCT a.CategoryId, a.[PropertyValueId], a.Property, PropertySchemaName  FROM [dbo].[EntityProperty_Summary] a where EntityTypeId= 1 AND CategoryId IN (4, 14, 18, 21) AND base.Id = [EntityBaseId] FOR XML RAW, ROOT('CredentialProperties')) CredentialProperties

	,isnull(Languages.Languages,'') As Languages	
	-- **************************************************************************************************
	--17-05-04 mp - these were added to Credential.SummaryCache and joined in summary 
	--		to be replaced by QualityAssurance
	,isnull(base.QARolesList,'') As QARolesList
	,isnull(base.AgentAndRoles,'') As AgentAndRoles
	--renaming this
	,isnull(base.QAOrgRolesList,'') As QAOrgRolesList

	-- to this
	,isnull(base.QAOrgRolesList,'') As Org_QARolesList
	,isnull(base.QAAgentAndRoles,'') As Org_QAAgentAndRoles

	-- ========================================================================
	--relationships is non QA - typically owns and offers, revoked, and renewed
	--, STUFF((SELECT '|' + ISNULL(NULLIF(CAST(a.[RelationshipTypeId] AS NVARCHAR(MAX)), ''), NULL) AS [text()] 
	--	FROM [dbo].[Entity.AgentRelationship] a inner join Entity b on a.EntityId = b.Id 
	--	WHERE b.EntityUid = base.RowId 
	--	FOR XML Path('')), 1,1,'') RelationshipTypes
	--now obsolete
	,'' as RelationshipTypes
	,'' as AgentRelationships

	--all entity to organization relationships with org information. 
	--Roles is from entity context, AgentContextRoles is from the agent context. Accredited By vs Accredits 
	 ,(SELECT DISTINCT AgentRelativeId As OrgId, AgentName, AgentUrl, EntityStateId, RoleIds as RelationshipTypeIds,  Roles as Relationships, AgentContextRoles FROM [dbo].[Entity.AgentRelationshipIdCSV]
			WHERE EntityTypeId= 1 AND EntityBaseId = base.id 
			FOR XML RAW, ROOT('AgentRelationshipsForEntity')) AgentRelationshipsForEntity

	 -- QualityAssurance is QA only
	 --18-10-08 mparsons - removed IsQARole, and return all. Use to facilitate widget filtering
	 --19-02-11 mparsons - this will be replaced by AgentRelationshipsForEntity
	 --AND [IsQARole]= 1
	 --,(SELECT DISTINCT [RelationshipTypeId] ,[SourceToAgentRelationship]   ,[AgentToSourceRelationship], Isnull([AgentUrl],'') As AgentUrl  ,[AgentRelativeId], Isnull(AgentName,'') As AgentName, IsQARole, [EntityStateId] FROM [dbo].[Entity_Relationship_AgentSummary]  WHERE [SourceEntityTypeId] = 1  and [SourceEntityBaseId] = base.id FOR XML RAW, ROOT('QualityAssurance')) QualityAssurance

	 -- **************************************************************************************************

 -- [Entity_Subjects] is a union of direct and indirect subjects
	, (SELECT a.[Subject], a.[Source], a.EntityTypeId, a.ReferenceBaseId FROM [dbo].[Entity_Subjects] a WHERE a.EntityTypeId = 1 AND a.EntityUid = base.RowId FOR XML RAW, ROOT('Subjects')) Subjects

 	, (SELECT a.[CategoryId], a.[ReferenceFrameworkId], a.[Name], a.[SchemaName], ISNULL(NULLIF(a.[CodeGroup], ''), NULL) CodeGroup, a.CodedNotation FROM [dbo].[Entity_ReferenceFramework_Summary] a inner join Entity b on a.EntityId = b.Id inner join [Credential] c on b.EntityUid = c.RowId where a.[CategoryId] IN (10, 11, 23) AND c.[Id] = base.[Id] FOR XML RAW, ROOT('Frameworks')) Frameworks
 	--, (SELECT a.Latitude, a.Longitude, a.Region, a.Country FROM [dbo].[Entity.Address] a inner join Entity b on a.EntityId = b.Id
		-- WHERE a.Latitude <> 0 AND b.EntityTypeId = 1 AND b.EntityUid = base.RowId 
		-- FOR XML RAW, ROOT('Addresses')) Addresses

	, (SELECT b.RowId, b.Id, b.EntityId, a.EntityUid, a.EntityTypeId, a.EntityBaseId, a.EntityBaseName, b.Id AS EntityAddressId, b.Name, b.IsPrimaryAddress, b.Address1, b.Address2, b.City, b.Region, b.PostOfficeBoxNumber, b.PostalCode, b.Country, b.Latitude, b.Longitude, b.Created, b.LastUpdated FROM dbo.Entity AS a INNER JOIN dbo.[Entity.Address] AS b ON a.Id = b.EntityId where a.[EntityUid] = base.[RowId] 
		FOR XML RAW, ROOT('Addresses')) Addresses

		-- addresses for owning org - will only be used if there is no address for the credential
	, (SELECT b.RowId, b.Id, b.EntityId, a.EntityUid, a.EntityTypeId, a.EntityBaseId, a.EntityBaseName, b.Id AS EntityAddressId, b.Name, b.IsPrimaryAddress, b.Address1, b.Address2, b.City, b.Region, b.PostOfficeBoxNumber, b.PostalCode, b.Country, b.Latitude, b.Longitude, b.Created, b.LastUpdated FROM dbo.Entity AS a INNER JOIN dbo.[Entity.Address] AS b ON a.Id = b.EntityId where a.[EntityUid] = base.OwningAgentUid 
		FOR XML RAW, ROOT('OrgAddresses')) OrgAddresses

	, (SELECT ccs.[Name], ccs.[TargetNodeDescription] [Description] FROM [dbo].[ConditionProfile_Competencies_Summary] ccs 
		where ccs.CredentialId = base.Id 
		FOR XML RAW, ROOT('Competencies')) Competencies


From #tempWorkTable work
	Inner join Credential_Summary base on work.Id = base.Id
	--Inner join Credential_Summary_Cache base on work.Id = base.Id
	Inner join Entity e on work.Id = e.EntityBaseId and e.EntityTypeId = 1

	left Join (select EntityId, count(*) as nbr from [Entity.Address] group by EntityId ) ea on base.EntityId = ea.EntityId

	--left join EntityProperty_EducationLevelCSV levelsCsv	on base.EntityId = levelsCsv.EntityId

	--left join EntityProperty_AudienceTypeCSV typesCsv on base.EntityId = typesCsv.EntityId

--17-05-04 mp - these were added to Credential.SummaryCache and joined in summary 
	--left join [Credential.QARolesCSV] qaRolesCsv	on work.id = qaRolesCsv.CredentialId

	left join Credential_ConditionProfilesCSV connectionsCsv on work.id = connectionsCsv.CredentialId
	--left join [Entity_SubjectsCSV] subjectsCsv		on base.EntityUid = subjectsCsv.EntityUid

	-- ========== check for a verifiable badge claim ========== 
	Left Join (SELECT c.CredentialId, count(*) as Total
		FROM [Entity.VerificationProfile] a
		inner join entity vpEntity							on a.RowId = vpEntity.EntityUid
		inner join  [dbo].[Entity.Credential] c on vpEntity.Id = c.EntityId
		inner join  [dbo].[Entity.Property] ep  on vpEntity.Id = ep.EntityId
		inner join [Codes.PropertyValue] b			on ep.PropertyValueId = b.Id
		where 	b.SchemaName = 'claimType:BadgeClaim'
		group by c.CredentialId

	) badgeClaims on base.Id = badgeClaims.CredentialId

	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.CostProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1  Group By b.EntityBaseId
	) costProfiles	on base.Id = costProfiles.EntityBaseId  
	--not ideal, but doing a total
	--left join (
	--Select ParentEntityUid, sum(isnull(TotalCost, 0)) As TotalCost from Entity_CostProfileTotal group by ParentEntityUid
	--) costs				
	--	on base.EntityUid = costs.ParentEntityUid

-- ========== total cost items - just for credential, no child items ========== 
	--left join (
	--				Select ParentEntityUid, Count(*) As Total from Entity_CostProfileTotal group by ParentEntityUid
	--				) costProfiles	on base.EntityUid = costProfiles.ParentEntityUid

-- ========== total cost items - just for credential, AND child items ========== 
	--left join (
	--	Select condProfParentEntityBaseId, Sum(TotalCostItems) As Total from [CostProfile_SummaryForSearch] 
	--	where condProfParentEntityTypeId =1  and TotalCostItems > 0
	--	group by condProfParentEntityBaseId 
	--	) allCostProfiles	on base.Id = allCostProfiles.condProfParentEntityBaseId

	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.CommonCost] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1  Group By b.EntityBaseId
		) CommonCost	on base.Id = CommonCost.EntityBaseId     
	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.CommonCondition] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1  Group By b.EntityBaseId
		) CommonCondition	on base.Id = CommonCondition.EntityBaseId     
	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.FinancialAlignmentProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1  Group By b.EntityBaseId 
		) FinancialAid	on base.Id = FinancialAid.EntityBaseId 
	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.Credential] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1  Group By b.EntityBaseId 
		) EmbeddedCredentials	on base.Id = EmbeddedCredentials.EntityBaseId 

	left join (
		SELECT parentId as EntityBaseId, Sum(HasTargetAssessment) As HasTargetAssessments, Sum(HasTargetCredential) As HasTargetCredentials, Sum(HasLearningOpportunity) as HasLearningOpportunities FROM [dbo].[Entity_ConditionProfileTargetsSummary] where ParentEntityTypeId = 1 and ConnectionTypeId = 1 and (HasTargetAssessment > 0 OR HasTargetCredential > 0 OR HasLearningOpportunity > 0) group by parentId
		) reqTargets	on base.Id = reqTargets.EntityBaseId 

	left join (
		SELECT parentId as EntityBaseId, Sum(HasTargetAssessment) As HasTargetAssessments, Sum(HasTargetCredential) As HasTargetCredentials, Sum(HasLearningOpportunity) as HasLearningOpportunities FROM [dbo].[Entity_ConditionProfileTargetsSummary] where ParentEntityTypeId = 1 and ConnectionTypeId = 2 and (HasTargetAssessment > 0 OR HasTargetCredential > 0 OR HasLearningOpportunity > 0) group by parentId
		) recommendedTargets	on base.Id = recommendedTargets.EntityBaseId 
	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.ProcessProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1  Group By b.EntityBaseId
		) processProfiles	on base.Id = processProfiles.EntityBaseId     
	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.RevocationProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1  Group By b.EntityBaseId
		) revocationProfiles	on base.Id = revocationProfiles.EntityBaseId   
	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.ReferenceFramework] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1 and CategoryId = 11 Group By b.EntityBaseId 
		) HasOccupations	on base.Id = HasOccupations.EntityBaseId   
	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.ReferenceFramework] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1 and CategoryId = 10 Group By b.EntityBaseId 
		) HasIndustries	on base.Id = HasIndustries.EntityBaseId 
	
	--left join (
	--	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.ReferenceFramework] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1 and CategoryId = 23 Group By b.EntityBaseId 
	--	) CIPCounts on base.Id = CIPCounts.EntityBaseId 

	left Join ( 
		SELECT     distinct base.Id, 
		CASE WHEN Languages IS NULL THEN ''           WHEN len(Languages) = 0 THEN ''          ELSE left(Languages,len(Languages)-1)     END AS Languages
		From dbo.credential base
		CROSS APPLY ( SELECT a.TextValue + '| '
			FROM [dbo].[Entity.Reference] a inner join [Entity] b on a.EntityId = b.Id 
			where b.EntityTypeId= 1 AND a.CategoryId = 65
			and base.Id = b.EntityBaseId FOR XML Path('')  ) D (Languages)
		where Languages is not null
	) Languages on base.Id = Languages.Id

	left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.ConditionProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1 Group By b.EntityBaseId 
		) HasConditionProfile	on base.Id = HasConditionProfile.EntityBaseId 
	 left join (
		Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.DurationProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 1  Group By b.EntityBaseId 
		) HasDuration	on base.Id = HasDuration.EntityBaseId  
-- =======================================================
left join (SELECT [ParentEntityUid] ,sum([AverageMinutes]) as [AverageMinutes] 
  FROM [dbo].[Entity_Duration_EntityAverage] group by [ParentEntityUid])  duration on base.EntityUid = duration.ParentEntityUid 

-- =========================================================
WHERE RowNumber > @first_id 
--and (base.RequiresCount  > 0 or base.RecommendsCount > 0)

order by RowNumber 

GO

grant execute on [Credential.ElasticSearch] to public
go