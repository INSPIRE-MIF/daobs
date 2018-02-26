/**
 * Copyright 2014-2016 European Environment Agency
 *
 * Licensed under the EUPL, Version 1.1 or – as soon
 * they will be approved by the European Commission -
 * subsequent versions of the EUPL (the "Licence");
 * You may not use this work except in compliance
 * with the Licence.
 * You may obtain a copy of the Licence at:
 *
 * https://joinup.ec.europa.eu/community/eupl/og_page/eupl
 *
 * Unless required by applicable law or agreed to in
 * writing, software distributed under the Licence is
 * distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.
 * See the Licence for the specific language governing
 * permissions and limitations under the Licence.
 */

package org.daobs.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;

import org.daobs.index.EsClientBean;

import org.daobs.index.EsRequestBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;


/**
 * API for index operations.
 */
@Api(value = "index",
    tags = "index",
    description = "Index operations")
@Controller
public class IndexController {

  @Autowired
  EsClientBean esClientBean;

  /**
   * Create index if not existing.
   *
   */
  @ApiOperation(value = "Create index if not existing",
      nickname = "createIndex")
  @RequestMapping(value = "/index",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.PUT)
  @ResponseBody
  public boolean createIndex(HttpServletRequest request)
      throws IOException {
    return esClientBean.checkIndices(request.getSession()
        .getServletContext()
        .getRealPath(""));
  }
}
