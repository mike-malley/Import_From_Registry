/** 
SELECT TOP (1000) [Id]
      ,[Created]
      ,[ReferencedId]
      ,[ReferencedCtid]
      ,[ReferencedEntityTypeId]
      ,[EntityUid]
      ,[IsResolved]
      ,[EntityBaseId]
  FROM [credFinder].[dbo].[Import.EntityResolution]

*/

--ALTER PROCEDURE [dbo].[Import_EntityResolution_RemoveDuplicates]
--            @MaxRecords int
--			,@DoingUpdate bit
--As
--begin 

Declare 

@cntr int
,@totalCount int
,@PrevReferencedId varchar(300)


,@Id int
,@ReferencedId varchar(300)
,@ReferencedEntityTypeId int
,@created datetime
,@IsResolved bit
,@EntityUid uniqueidentifier
,@EntityBaseId int

,@MaxRecords int

set @MaxRecords = 20
set @cntr= 0
set @totalCount= 0
set @PrevReferencedId = ''

-- ===============================================
	DECLARE thisCursor CURSOR FOR
      SELECT  Id, created,  ReferencedId, ReferencedCtid, ReferencedEntityTypeId, IsResolved,EntityUid, EntityBaseId
		FROM [Import.EntityResolution]
		where 
		ReferencedCtid IN
        (	SELECT     ReferencedCtid
            FROM [Import.EntityResolution]
            GROUP BY ReferencedCtid
            HAVING      (COUNT(*) > 1)
		)
		ORDER BY ReferencedCtid, created

		OPEN thisCursor
	FETCH NEXT FROM thisCursor INTO @Id, @created, @ReferencedId,@ReferencedEntityTypeId,@IsResolved,
	@EntityUid, @EntityBaseId
	WHILE @@FETCH_STATUS = 0 BEGIN
		set @cntr = @cntr+ 1
		if @MaxRecords > 0 AND @cntr > @MaxRecords begin
			print '### Early exit based on @MaxRecords = ' + convert(varchar, @MaxRecords)
			select 'exiting',  getdate()
			set @cntr = @cntr - 1
			BREAK
			End	  



		
		FETCH NEXT FROM thisCursor INTO @Id, @ResourceIntId, @Title,@Desc,@IsActive
	END

	CLOSE thisCursor
	DEALLOCATE thisCursor